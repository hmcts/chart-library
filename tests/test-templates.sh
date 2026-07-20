#!/usr/bin/env bash

set -e

helm lint library/ --values library/ci-values.yaml
helm unittest --help

#change library chart to application
yq eval -i '.type = "application"' library/Chart.yaml

# Snapshot tests: assert full rendered output hasn't changed unexpectedly.
# Run twice — ci-values.yaml covers standard config, ci-values-lang.yaml covers
# language-specific overrides (e.g. JVM flags, language env vars). Both sets of
# snapshots must be committed and kept up to date.
helm unittest --values library/ci-values.yaml library -q -f 'tests/snapshot-tests/*.yaml'
helm unittest --values library/ci-values-lang.yaml library -q -f 'tests/snapshot-tests/*.yaml'

# Assertion tests: verify specific field values and structural rules against
# a fully populated values set. ci-values.yaml and ci-values-lang.yaml ensure all
# optional sections are enabled so every assertion path is exercised.
helm unittest --values library/ci-values.yaml library -q -f 'tests/unit-tests/*.yaml'
helm unittest --values library/ci-values-lang.yaml library -q -f 'tests/unit-tests/*.yaml'

# Conditional branch tests: verify that optional blocks render when their guard
# condition is met and are absent when it is not. ci-values-minimal.yaml supplies
# only the required image field so each test's `set:` values are the sole input —
# preventing full ci-values from silently satisfying a condition under test.
helm unittest --values library/ci-values-minimal.yaml library -q -f 'tests/unit-tests/conditional/*.yaml'

#revert test changes
yq eval -i '.type = "library"' library/Chart.yaml
