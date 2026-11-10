"""Record Helm helper renames and read migration history between Git refs."""

import argparse
import json
import re
import subprocess
from datetime import datetime
from pathlib import Path

DECLARATIONS = "library/template-migrations.json"
STABLE = re.compile(r"v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\Z")
IDENTIFIER = re.compile(r"hmcts\.[A-Za-z0-9_.-]+\Z")
# Quoted strings and comments must be consumed before looking for an action's end.
ACTION = re.compile(r'{{-?\s*(?:/\*[\s\S]*?\*/\s*-?}}|(?:`[^`]*`|"(?:\\.|[^"\\])*"|[^"`])*?-?}})')
TOKEN = re.compile(r'`[^`]*`|"(?:\\.|[^"\\])*"|[A-Za-z_][A-Za-z0-9_.]*|[^\s]')


class MigrationError(ValueError):
    pass


def command(*args: str, cwd: Path | None = None) -> str:
    return subprocess.run(args, cwd=cwd, check=True, text=True, capture_output=True).stdout


def version(value: str) -> tuple[int, int, int]:
    match = STABLE.fullmatch(value)
    if not match:
        raise MigrationError(f"Expected an exact stable version, got {value!r}")
    return tuple(int(part) for part in match.groups())


def normalized(value: str) -> str:
    return ".".join(str(part) for part in version(value))


def strings(text: str, operations: set[str]):
    """Yield literal operands of named-template operations, never comment text."""
    for action in ACTION.finditer(text):
        body = action.group()
        if re.match(r"{{-?\s*/\*", body):
            continue
        tokens = list(TOKEN.finditer(body[2:-2]))
        for index, token in enumerate(tokens[:-1]):
            if token.group() not in operations:
                continue
            operand = tokens[index + 1]
            literal = operand.group()
            if literal.startswith(('"', "`")):
                name = json.loads(literal) if literal.startswith('"') else literal[1:-1]
                start = action.start() + 2 + operand.start()
                yield name, start, start + len(literal)


def definitions(text: str) -> set[str]:
    return {name for name, _, _ in strings(text, {"define"})}


def files_at(root: Path, ref: str | None) -> dict[str, str]:
    if ref is None:
        return {
            path.relative_to(root).as_posix(): path.read_text()
            for path in sorted((root / "library/templates").rglob("*"))
            if path.is_file()
        }
    paths = command("git", "ls-tree", "-r", "--name-only", ref, "--", "library/templates", cwd=root)
    return {path: command("git", "show", f"{ref}:{path}", cwd=root) for path in paths.splitlines()}


def read_declarations(text: str) -> list[dict[str, str]]:
    data = json.loads(text)
    if not isinstance(data, dict) or set(data) != {"migrations"} or not isinstance(data["migrations"], list):
        raise MigrationError("Declaration file must contain only a migrations list")
    result: list[dict[str, str]] = []
    for entry in data["migrations"]:
        if not isinstance(entry, dict) or set(entry) != {"from", "to", "sourceFile"}:
            raise MigrationError(f"Invalid migration declaration: {entry!r}")
        if not all(isinstance(value, str) for value in entry.values()):
            raise MigrationError("Migration fields must be strings")
        if not all(IDENTIFIER.fullmatch(entry[key]) for key in ("from", "to")):
            raise MigrationError("Mappings require exact hmcts helper identifiers")
        path = Path(entry["sourceFile"])
        if path.is_absolute() or ".." in path.parts or not path.as_posix().startswith("library/templates/"):
            raise MigrationError(f"Invalid sourceFile: {path}")
        result.append(entry)
    return result


def declarations_at(root: Path, ref: str | None) -> list[dict[str, str]]:
    if ref is None:
        return read_declarations((root / DECLARATIONS).read_text())
    found = command("git", "ls-tree", "--name-only", ref, "--", DECLARATIONS, cwd=root).strip()
    return read_declarations(command("git", "show", f"{ref}:{DECLARATIONS}", cwd=root)) if found else []


def release_changes(root: Path, base: str, target_ref: str | None = None) -> list[dict[str, str]]:
    old_entries = declarations_at(root, base)
    entries = declarations_at(root, target_ref)
    if entries[:len(old_entries)] != old_entries:
        raise MigrationError("Released declarations are append-only")
    pending = entries[len(old_entries):]
    edges: dict[str, dict[str, str]] = {}
    for entry in pending:
        source = entry["from"]
        if source in edges:
            raise MigrationError(f"Duplicate source mapping: {source}")
        edges[source] = entry
    previous_files = files_at(root, base)
    current_files = files_at(root, target_ref)
    previous = set().union(*(definitions(text) for text in previous_files.values()))
    current = set().union(*(definitions(text) for text in current_files.values()))
    changes: list[dict[str, str]] = []
    reached: set[str] = set()
    for source in edges:
        node = source
        visited: set[str] = set()
        while node in edges:
            if node in visited:
                raise MigrationError(f"Migration cycle at {node}")
            visited.add(node)
            node = edges[node]["to"]
        if node not in current:
            raise MigrationError(f"Target helper does not exist: {node}")
        if source in previous:
            reached.update(visited)
            final_entry = edges[next(key for key in visited if edges[key]["to"] == node)]
            if node not in definitions(current_files.get(final_entry["sourceFile"], "")):
                raise MigrationError(f"Target helper is not defined in {final_entry['sourceFile']}")
            changes.append({**final_entry, "from": source, "to": node})
    if set(edges) != reached:
        raise MigrationError("Mapping source does not originate in the previous release")
    unmapped = {name for name in previous - current if IDENTIFIER.fullmatch(name)} - set(edges)
    if unmapped:
        raise MigrationError(f"Removed helpers lack migrations: {', '.join(sorted(unmapped))}")
    return sorted(changes, key=lambda entry: entry["from"])


def record(root: Path, base: str, renames: dict[str, str] | None = None) -> None:
    """Append exact renames produced by the existing post-merge bump."""
    old_files, new_files = files_at(root, base), files_at(root, None)
    entries = declarations_at(root, None)
    for path, old_text in old_files.items():
        old_names = definitions(old_text)
        new_names = definitions(new_files.get(path, ""))
        sources = old_names - new_names if renames is None else old_names & renames.keys()
        for source in sorted(sources):
            identity = re.sub(r"\.v\d+(?=\.tpl$|$)", ".VERSION", source)
            candidates = [
                name for name in (new_names - old_names if renames is None else new_names)
                if re.sub(r"\.v\d+(?=\.tpl$|$)", ".VERSION", name) == identity
            ]
            if renames is not None:
                candidates = [name for name in candidates if name == renames.get(source)]
            if len(candidates) != 1:
                raise MigrationError(f"Cannot record an unambiguous rename for {source}")
            entry = {"from": source, "to": candidates[0], "sourceFile": path}
            if entry not in entries:
                entries.append(entry)
    (root / DECLARATIONS).write_text(json.dumps({"migrations": entries}, indent=2) + "\n")


def generate(root: Path, base: str, target: str, released_at: str) -> dict:
    previous = normalized(base)
    target = normalized(target)
    if version(previous) >= version(target):
        raise MigrationError("Release version must be newer than its predecessor")
    return {
        "schemaVersion": 1,
        "chartLibraryVersion": target,
        "previousChartLibraryVersion": previous,
        "releasedAt": released_at,
        "changes": release_changes(root, base),
    }


def validate_asset(asset: dict) -> None:
    if not isinstance(asset, dict) or set(asset) != {
        "schemaVersion", "chartLibraryVersion", "previousChartLibraryVersion", "releasedAt", "changes"
    }:
        raise MigrationError("Invalid migration asset fields")
    if type(asset["schemaVersion"]) is not int or asset["schemaVersion"] != 1:
        raise MigrationError("Unsupported migration schema version")
    if not all(isinstance(asset[key], str) for key in (
        "chartLibraryVersion", "previousChartLibraryVersion", "releasedAt"
    )):
        raise MigrationError("Asset versions and releasedAt must be strings")
    if version(asset["previousChartLibraryVersion"]) >= version(asset["chartLibraryVersion"]):
        raise MigrationError("Invalid asset version range")
    try:
        timestamp = datetime.fromisoformat(asset["releasedAt"].replace("Z", "+00:00"))
    except ValueError as error:
        raise MigrationError("Invalid releasedAt timestamp") from error
    if timestamp.tzinfo is None:
        raise MigrationError("releasedAt must include a timezone")
    entries = read_declarations(json.dumps({"migrations": asset["changes"]}))
    sources = [entry["from"] for entry in entries]
    if len(set(sources)) != len(sources):
        raise MigrationError("Duplicate source mappings in asset")
    if set(sources) & {entry["to"] for entry in entries}:
        raise MigrationError("Asset mappings must be collapsed to final release targets")


def resolve(assets: list[dict], base: str, target: str, baseline: str) -> list[dict]:
    if version(base) < version(baseline):
        raise MigrationError("Base predates rollout baseline; perform a manual migration")
    if version(target) < version(base):
        raise MigrationError("Downgrades require reverting dependency and helper changes together")
    selected = []
    seen: set[tuple[int, int, int]] = set()
    for asset in assets:
        validate_asset(asset)
        key = version(asset["chartLibraryVersion"])
        if version(base) < key <= version(target):
            if key in seen:
                raise MigrationError("Duplicate release assets")
            seen.add(key)
            selected.append(asset)
    selected.sort(key=lambda asset: version(asset["chartLibraryVersion"]))
    predecessor = version(base)
    for asset in selected:
        if version(asset["previousChartLibraryVersion"]) != predecessor:
            raise MigrationError("Incomplete migration release chain")
        predecessor = version(asset["chartLibraryVersion"])
    if predecessor != version(target):
        raise MigrationError("Missing target migration asset")
    return selected


def rewrite(chart: Path, assets: list[dict]) -> dict[str, int]:
    chart = chart.resolve()
    if not (chart / "templates").is_dir():
        raise MigrationError(f"Chart template directory does not exist: {chart / 'templates'}")
    for asset in assets:
        validate_asset(asset)
    changes: dict[Path, str] = {}
    counts: dict[str, int] = {}
    for path in sorted((chart / "templates").rglob("*")):
        if not path.is_file():
            continue
        if path.is_symlink() or any(parent.is_symlink() for parent in path.parents):
            raise MigrationError(f"Refusing a symlinked template: {path}")
        original = path.read_text()
        updated = original
        for asset in assets:
            mapping = {entry["from"]: entry["to"] for entry in asset["changes"]}
            replacements = [
                (start, end, json.dumps(mapping[name]))
                for name, start, end in strings(updated, {"include", "template"})
                if name in mapping
            ]
            for start, end, replacement in reversed(replacements):
                updated = updated[:start] + replacement + updated[end:]
            if replacements:
                counts[asset["chartLibraryVersion"]] = counts.get(asset["chartLibraryVersion"], 0) + len(replacements)
        if updated != original:
            changes[path] = updated
    for path, text in changes.items():
        path.write_text(text)
    return counts


def previous_tag(root: Path, target: str) -> str:
    tags = command("git", "tag", "--merged", "HEAD", cwd=root).splitlines()
    eligible = [tag for tag in tags if STABLE.fullmatch(tag) and version(tag) < version(target)]
    if not eligible:
        raise MigrationError("No previous stable release tag; configure the rollout baseline first")
    latest = max(version(tag) for tag in eligible)
    matches = [tag for tag in eligible if version(tag) == latest]
    if len(matches) != 1:
        raise MigrationError("Ambiguous predecessor tags")
    return matches[0]


def history(root: Path, base: str, target: str) -> dict:
    command("git", "merge-base", "--is-ancestor", base, target, cwd=root)
    if not command("git", "ls-tree", "--name-only", target, "--", DECLARATIONS, cwd=root).strip():
        raise MigrationError("Target release predates recorded migration history")
    return {
        "schemaVersion": 1,
        "chartLibraryVersion": normalized(target),
        "previousChartLibraryVersion": normalized(base),
        "releasedAt": command("git", "show", "-s", "--format=%cI", target, cwd=root).strip(),
        "changes": release_changes(root, base, target),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    sub = parser.add_subparsers(dest="action", required=True)
    for name in ("validate", "record"):
        sub.add_parser(name).add_argument("--base", required=True)
    generate_parser = sub.add_parser("generate")
    generate_parser.add_argument("--base", required=True)
    generate_parser.add_argument("--target", required=True)
    generate_parser.add_argument("--released-at", required=True)
    history_parser = sub.add_parser("history")
    history_parser.add_argument("--base", required=True)
    history_parser.add_argument("--target", required=True)
    history_parser.add_argument("--chart", type=Path)
    apply_parser = sub.add_parser("apply")
    apply_parser.add_argument("--assets", type=Path, required=True)
    apply_parser.add_argument("--base", required=True)
    apply_parser.add_argument("--target", required=True)
    apply_parser.add_argument("--baseline", required=True)
    apply_parser.add_argument("--chart", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.action == "validate":
            print(json.dumps(release_changes(args.root, args.base), indent=2))
        elif args.action == "record":
            record(args.root, args.base)
        elif args.action == "generate":
            asset = generate(args.root, args.base, args.target, args.released_at)
            validate_asset(asset)
            print(json.dumps(asset, indent=2))
        elif args.action == "history":
            asset = history(args.root, args.base, args.target)
            validate_asset(asset)
            if args.chart is not None:
                print(json.dumps({"rewrites": rewrite(args.chart, [asset])}, indent=2))
            else:
                print(json.dumps(asset, indent=2))
        elif args.action == "apply":
            assets = [json.loads(path.read_text()) for path in sorted(args.assets.glob("*.json"))]
            selected = resolve(assets, args.base, args.target, args.baseline)
            print(json.dumps({"releases": [asset["chartLibraryVersion"] for asset in selected],
                              "rewrites": rewrite(args.chart, selected)}, indent=2))
    except (MigrationError, OSError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        message = error.stderr if isinstance(error, subprocess.CalledProcessError) else str(error)
        parser.exit(1, f"Migration failed: {message}\n")


if __name__ == "__main__":
    main()
