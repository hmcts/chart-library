import os
import json
import re
import subprocess
import sys
from pathlib import Path

from template_migrations import (
    ACTION,
    TOKEN,
    MigrationError,
    definitions,
    files_at,
    record,
    recording_declarations,
)


def helper_literals(text: str):
    for action in ACTION.finditer(text):
        if re.match(r"{{-?\s*/\*", action.group()):
            continue
        for token in TOKEN.finditer(action.group()):
            if token.group().startswith(('"', "`")):
                yield action.start() + token.start(), action.start() + token.end(), token.group()


def bump(root: Path, baseline: str, changed_files: list[str]) -> bool:
    recording_declarations(root)
    previous = set().union(*(definitions(text) for text in files_at(root, baseline).values()))
    current_files = files_at(root, None)
    selected: set[str] = set()
    for path in changed_files:
        selected.update(definitions(current_files.get(path, "")) & previous)
    while True:
        expanded = set(selected)
        for text in current_files.values():
            if any(literal[1:-1] in selected for _, _, literal in helper_literals(text)):
                expanded.update(definitions(text) & previous)
        if expanded == selected:
            break
        selected = expanded
    mapping = {}
    for name in selected:
        updated, count = re.subn(r"\.v(\d+)(?=\.tpl$|$)",
                                lambda match: f".v{int(match[1]) + 1}", name)
        if count:
            mapping[name] = updated
    for path, text in current_files.items():
        replacements = []
        for start, end, literal in helper_literals(text):
            if literal[1:-1] in mapping:
                replacements.append((start, end, literal[0] + mapping[literal[1:-1]] + literal[-1]))
        for start, end, replacement in reversed(replacements):
            text = text[:start] + replacement + text[end:]
        if replacements:
            (root / path).write_text(text)
    if mapping:
        record(root, "HEAD", mapping)
    return bool(mapping)


if __name__ == "__main__":
    try:
        baseline = os.environ["BASELINE_REF"]
        changed = os.environ["CHANGED_FILES"].split()
        if bump(Path.cwd(), baseline, changed):
            print("version_updated")
    except (KeyError, MigrationError, OSError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        message = error.stderr if isinstance(error, subprocess.CalledProcessError) else str(error)
        sys.exit(f"Template bump failed: {message}")
