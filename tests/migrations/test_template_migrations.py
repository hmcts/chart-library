import importlib.util
import json
import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
import template_migrations as migrations


def change(source="hmcts.a.v1.tpl", target="hmcts.a.v2.tpl"):
    return {"from": source, "to": target,
            "sourceFile": "library/templates/v2/_a.tpl"}


def asset(previous, target, changes=None):
    return {"schemaVersion": 1, "chartLibraryVersion": target,
            "previousChartLibraryVersion": previous,
            "releasedAt": "2026-11-09T12:00:00Z",
            "changes": changes or []}


class RepositoryFixture:
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.templates = self.root / "library/templates/v2"
        self.templates.mkdir(parents=True)
        self.write_helper("hmcts.a.v1.tpl")
        self.write_entries([])
        self.git("init", "-q")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "Migration tests")
        self.commit()
        self.git("tag", "2.3.1")

    def git(self, *args):
        return migrations.command("git", *args, cwd=self.root)

    def commit(self):
        self.git("add", ".")
        self.git("commit", "-qm", "fixture")

    def write_helper(self, name):
        (self.templates / "_a.tpl").write_text('{{- define "' + name + '" -}}ok{{- end -}}\n')

    def write_entries(self, entries):
        (self.root / migrations.DECLARATIONS).write_text(json.dumps({"migrations": entries}))


class RepositoryTest(RepositoryFixture, unittest.TestCase):
    def test_first_bump_creates_missing_history(self):
        (self.root / migrations.DECLARATIONS).unlink()
        self.commit()
        spec = importlib.util.spec_from_file_location(
            "bump", Path(migrations.__file__).with_name("bump-tpl-versions.py"))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertTrue(module.bump(self.root, "HEAD", ["library/templates/v2/_a.tpl"]))
        self.assertEqual(migrations.declarations_at(self.root, None), [change()])

    def test_invalid_or_deleted_history_fails_before_template_writes(self):
        spec = importlib.util.spec_from_file_location(
            "bump", Path(migrations.__file__).with_name("bump-tpl-versions.py"))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        helper = self.templates / "_a.tpl"
        original = helper.read_bytes()
        history_file = self.root / migrations.DECLARATIONS
        history_file.write_text("invalid json")
        with self.assertRaises((json.JSONDecodeError, migrations.MigrationError)):
            module.bump(self.root, "HEAD", ["library/templates/v2/_a.tpl"])
        self.assertEqual(helper.read_bytes(), original)
        history_file.unlink()
        with self.assertRaisesRegex(migrations.MigrationError, "missing"):
            module.bump(self.root, "HEAD", ["library/templates/v2/_a.tpl"])
        self.assertEqual(helper.read_bytes(), original)

    def test_release_asset_and_empty_release(self):
        generated = migrations.generate(self.root, "2.3.1", "v2.3.2", "2026-11-09T12:00:00Z")
        self.assertEqual(generated, asset("2.3.1", "2.3.2"))
        self.write_helper("hmcts.a.v2.tpl")
        self.write_entries([change()])
        generated = migrations.generate(self.root, "2.3.1", "2.3.2", "2026-11-09T12:00:00Z")
        self.assertEqual(generated["changes"], [change()])
        self.commit()
        self.git("tag", "2.3.2")
        self.assertEqual(migrations.release_changes(self.root, "2.3.2"), [])

    def test_multiple_merges_collapse_to_released_source(self):
        self.write_helper("hmcts.a.v3.tpl")
        self.write_entries([change(), change("hmcts.a.v2.tpl", "hmcts.a.v3.tpl")])
        self.assertEqual(migrations.release_changes(self.root, "2.3.1"),
                         [change("hmcts.a.v1.tpl", "hmcts.a.v3.tpl")])

    def test_record_exact_pairs_with_and_without_tpl_suffix(self):
        (self.templates / "_a.tpl").write_text(
            '{{ define "hmcts.a.v2.tpl" }}{{ end }}{{ define "hmcts.a.v2" }}{{ end }}')
        # The wrapper is a new definition, not an old helper rename.
        migrations.record(self.root, "HEAD")
        self.assertEqual(migrations.declarations_at(self.root, None), [change()])
        migrations.record(self.root, "HEAD")
        self.assertEqual(migrations.declarations_at(self.root, None), [change()])

    def test_released_history_is_append_only(self):
        self.write_entries([change()])
        self.commit()
        self.git("tag", "2.3.2")
        self.write_entries([])
        with self.assertRaisesRegex(migrations.MigrationError, "append-only"):
            migrations.release_changes(self.root, "2.3.2")

    def test_invalid_declarations(self):
        for entries, message in (
            ([change(), change()], "Duplicate"),
            ([change(), change("hmcts.a.v2.tpl", "hmcts.a.v1.tpl")], "cycle"),
            ([change("hmcts.unknown.v1.tpl")], "originate"),
            ([change(target="hmcts.missing.v2.tpl")], "does not exist"),
        ):
            with self.subTest(message=message):
                self.write_helper("hmcts.a.v2.tpl")
                self.write_entries(entries)
                with self.assertRaisesRegex(migrations.MigrationError, message):
                    migrations.release_changes(self.root, "2.3.1")

    def test_missing_mapping_and_wrong_file(self):
        self.write_helper("hmcts.a.v2.tpl")
        with self.assertRaisesRegex(migrations.MigrationError, "lack migrations"):
            migrations.release_changes(self.root, "2.3.1")
        entry = change()
        entry["sourceFile"] = "library/templates/v2/_missing.tpl"
        self.write_entries([entry])
        with self.assertRaisesRegex(migrations.MigrationError, "not defined"):
            migrations.release_changes(self.root, "2.3.1")

    def test_bump_propagates_exact_names_and_records_all_pairs(self):
        spec = importlib.util.spec_from_file_location(
            "bump", Path(migrations.__file__).with_name("bump-tpl-versions.py"))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        (self.templates / "_b.tpl").write_text(
            '{{ define "hmcts.b.v1" }}{{ include "hmcts.a.v1.tpl" . }}{{ end }}')
        (self.templates / "_a.tpl").write_text(
            '{{ define "hmcts.a.v1.tpl" }}ok{{ end }}\n'
            '{{ define "hmcts.a.v10.tpl" }}ten{{ end }}')
        self.commit()
        self.git("tag", "before")
        self.assertTrue(module.bump(self.root, "before", ["library/templates/v2/_b.tpl"]))
        self.assertFalse(module.bump(self.root, "before", ["library/templates/v2/_b.tpl"]))
        self.assertEqual(definitions := migrations.definitions((self.templates / "_a.tpl").read_text()),
                         {"hmcts.a.v1.tpl", "hmcts.a.v10.tpl"})
        self.assertNotIn("hmcts.a.v2.tpl", definitions)
        # Change A next; dependency propagation must also bump B.
        self.commit()
        self.git("tag", "next")
        self.assertTrue(module.bump(self.root, "next", ["library/templates/v2/_a.tpl"]))
        entries = migrations.declarations_at(self.root, None)
        self.assertIn(change(), entries)
        self.assertIn({"from": "hmcts.b.v2", "to": "hmcts.b.v3",
                       "sourceFile": "library/templates/v2/_b.tpl"}, entries)
        self.assertEqual(migrations.definitions((self.templates / "_a.tpl").read_text()),
                         {"hmcts.a.v2.tpl", "hmcts.a.v11.tpl"})

    def test_previous_tag_uses_stable_ancestor_versions(self):
        self.git("tag", "v2.4.0-beta.1")
        self.assertEqual(migrations.previous_tag(self.root, "2.4.0"), "2.3.1")
        self.git("tag", "v2.3.1")
        with self.assertRaisesRegex(migrations.MigrationError, "Ambiguous"):
            migrations.previous_tag(self.root, "2.4.0")


class ConsumerTest(unittest.TestCase):
    def test_literal_parser_ignores_comments_strings_and_embedded_delimiters(self):
        text = (
            '{{/* {{ template "hmcts.a.v1.tpl" . }} */}}\n'
            '{{ printf "}} include \\"hmcts.a.v1.tpl\\"" }}\n'
            '{{- $rendered := include "hmcts.a.v1.tpl" . -}}\n'
            '{{ template `hmcts.b.v1` . }}'
        )
        self.assertEqual([name for name, _, _ in migrations.strings(text, {"include", "template"})],
                         ["hmcts.a.v1.tpl", "hmcts.b.v1"])

    def test_skipped_releases_unchanged_helpers_and_idempotency(self):
        assets = [asset("2.3.1", "2.3.2", [change()]),
                  asset("2.3.2", "2.4.0"),
                  asset("2.4.0", "2.5.0", [change("hmcts.a.v2.tpl", "hmcts.a.v3.tpl")])]
        selected = migrations.resolve(list(reversed(assets)), "2.3.1", "2.5.0", "2.3.1")
        with tempfile.TemporaryDirectory() as directory:
            chart = Path(directory)
            (chart / "templates").mkdir()
            path = chart / "templates/deployment.yaml"
            original = (
                '{{/* template "hmcts.a.v1.tpl" . */}}\n'
                'literal: hmcts.a.v1.tpl\n'
                '{{- template "hmcts.a.v1.tpl" . -}}\n'
                '{{ include `hmcts.a.v1.tpl` . | indent 2 }}\n'
                '{{ printf "include \\"hmcts.a.v1.tpl\\"" }}\n'
                '{{ include "hmcts.a.v10.tpl" . }}\n'
            )
            path.write_text(original)
            (chart / "values.yaml").write_text("hmcts.a.v1.tpl")
            self.assertEqual(migrations.rewrite(chart, selected), {"2.3.2": 2, "2.5.0": 2})
            expected = original.replace(
                '{{- template "hmcts.a.v1.tpl"', '{{- template "hmcts.a.v3.tpl"'
            ).replace('include `hmcts.a.v1.tpl` .', 'include "hmcts.a.v3.tpl" .')
            self.assertEqual(path.read_text(), expected)
            self.assertEqual((chart / "values.yaml").read_text(), "hmcts.a.v1.tpl")
            self.assertEqual(migrations.rewrite(chart, selected), {})

    def test_missing_invalid_duplicate_and_downgrade(self):
        for assets, base, target, message in (
            ([], "2.3.1", "2.4.0", "Missing target"),
            ([asset("2.3.2", "2.4.0")], "2.3.1", "2.4.0", "Incomplete"),
            ([asset("2.3.1", "2.4.0")] * 2, "2.3.1", "2.4.0", "Duplicate"),
            ([], "2.4.0", "2.3.1", "Downgrades"),
            ([], "2.2.0", "2.4.0", "predates"),
        ):
            with self.subTest(message=message):
                with self.assertRaisesRegex(migrations.MigrationError, message):
                    migrations.resolve(assets, base, target, "2.3.1")
        self.assertEqual(migrations.resolve([], "2.3.1", "2.3.1", "2.3.1"), [])

    def test_asset_schema_errors(self):
        for invalid in (
            {**asset("2.3.1", "2.4.0"), "schemaVersion": 2},
            {**asset("2.3.1", "2.4.0"), "changes": [change(), change()]},
            {**asset("2.3.1", "2.4.0"), "releasedAt": "yesterday"},
            {**asset("2.3.1", "2.4.0"), "changes": [{**change(), "type": "execute"}]},
        ):
            with self.subTest(invalid=invalid):
                with self.assertRaises(migrations.MigrationError):
                    migrations.validate_asset(invalid)

    def test_failure_does_not_write_any_file(self):
        with tempfile.TemporaryDirectory() as directory:
            chart = Path(directory)
            (chart / "templates").mkdir()
            path = chart / "templates/test.yaml"
            path.write_text('{{ include "hmcts.a.v1.tpl" . }}')
            before = path.read_bytes()
            with self.assertRaises(migrations.MigrationError):
                migrations.rewrite(chart, [asset("2.3.1", "2.4.0", [change()]), {}])
            self.assertEqual(path.read_bytes(), before)

    def test_symlinked_templates_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            chart = Path(directory)
            (chart / "templates").mkdir()
            source = chart / "outside.yaml"
            source.write_text('{{ include "hmcts.a.v1.tpl" . }}')
            (chart / "templates/link.yaml").symlink_to(source)
            with self.assertRaisesRegex(migrations.MigrationError, "symlink"):
                migrations.rewrite(chart, [asset("2.3.1", "2.4.0", [change()])])
            self.assertIn("v1", source.read_text())

    def test_versions_use_semver_order_not_lexical_or_consumer_version(self):
        selected = migrations.resolve(
            [asset("2.9.0", "2.10.0"), asset("2.8.0", "2.9.0")],
            "2.8.0", "2.10.0", "2.3.1")
        self.assertEqual([entry["chartLibraryVersion"] for entry in selected], ["2.9.0", "2.10.0"])
        for value in ("2.03.1", "2.4.0-alpha", "latest", ">=2.3.1", "2.3"):
            with self.assertRaises(migrations.MigrationError):
                migrations.version(value)


class HistoryTest(RepositoryFixture, unittest.TestCase):
    def test_tagged_history_includes_skipped_releases_but_not_later_master_changes(self):
        self.write_helper("hmcts.a.v2.tpl")
        self.write_entries([change()])
        self.commit()
        self.git("tag", "2.3.2")
        self.commit_empty_release("2.3.3")
        self.write_helper("hmcts.a.v3.tpl")
        entries = [change(), change("hmcts.a.v2.tpl", "hmcts.a.v3.tpl")]
        self.write_entries(entries)
        self.commit()
        self.git("tag", "2.4.0")
        self.write_helper("hmcts.a.v4.tpl")
        self.write_entries(entries + [change("hmcts.a.v3.tpl", "hmcts.a.v4.tpl")])
        result = migrations.history(self.root, "2.3.1", "2.4.0")
        migrations.validate_asset(result)
        self.assertEqual(result["changes"], [change("hmcts.a.v1.tpl", "hmcts.a.v3.tpl")])
        self.assertEqual(migrations.history(self.root, "2.3.2", "2.3.3")["changes"], [])

    def commit_empty_release(self, tag):
        self.git("commit", "--allow-empty", "-qm", "empty release")
        self.git("tag", tag)


class RealChartTest(RepositoryFixture, unittest.TestCase):
    @unittest.skipUnless(shutil.which("helm"), "Helm is required for render equivalence")
    def test_actual_library_render_is_preserved_by_propagated_bump(self):
        source = Path(migrations.__file__).resolve().parents[1] / "library"
        (self.templates / "_a.tpl").unlink()
        shutil.copytree(source, self.root / "library", dirs_exist_ok=True)
        chart_file = self.root / "library/Chart.yaml"
        chart_text, replacements = re.subn(r"(?m)^type: library$", "type: application", chart_file.read_text())
        self.assertEqual(replacements, 1)
        chart_file.write_text(chart_text)
        self.write_entries([])
        self.commit()
        self.git("tag", "real-baseline")
        before = migrations.command("helm", "template", "migration-test", "library",
                                    "--values", "library/ci-values.yaml", cwd=self.root)
        spec = importlib.util.spec_from_file_location(
            "bump", Path(migrations.__file__).with_name("bump-tpl-versions.py"))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertTrue(module.bump(self.root, "real-baseline", ["library/templates/v2/_deployment.tpl"]))
        mappings = migrations.release_changes(self.root, "real-baseline")
        self.assertTrue(any(entry["from"].startswith("hmcts.deployment.") for entry in mappings))
        after = migrations.command("helm", "template", "migration-test", "library",
                                   "--values", "library/ci-values.yaml", cwd=self.root)
        self.assertEqual(before, after)


class PipelineTest(unittest.TestCase):
    def test_release_jobs_are_unchanged_and_need_no_new_credentials(self):
        root = Path(migrations.__file__).resolve().parents[1]
        pipeline = (root / "azure-pipelines.yaml").read_text()
        for name in ("Release", "Release_Sbox"):
            block = re.search(rf"(?ms)^  - job: {name}\n(.*?)(?=^  - job: |\Z)", pipeline)
            self.assertIsNotNone(block)
            self.assertIn("    dependsOn: Validate\n", block[1])
        self.assertNotIn("Release_Metadata", pipeline)
        self.assertNotIn("chartMigrationGithubToken", pipeline)
        self.assertNotIn("pip install", pipeline)
        workflow = (root / ".github/workflows/bump-tpl-version.yaml").read_text()
        self.assertIn("git add library/templates/v2 library/template-migrations.json", workflow)
        self.assertNotIn("pip install", workflow)


if __name__ == "__main__":
    unittest.main()
