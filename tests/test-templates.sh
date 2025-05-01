#!/usr/bin/env bash

set -e

helm lint library/ --values library/ci-values.yaml
helm unittest --help

#change library chart to application
yq eval -i '.type = "application"' library/Chart.yaml

# Snapshot tests for library chart
helm unittest --values library/ci-values.yaml library -q -f 'tests/snapshot-tests/*.yaml'
helm unittest --values library/ci-values-lang.yaml library -q -f 'tests/snapshot-tests/*.yaml'

# Unit tests for library chart
helm unittest --values library/ci-values.yaml library -q -f 'tests/unit-tests/*.yaml'
helm unittest --values library/ci-values-lang.yaml library -q -f 'tests/unit-tests/*.yaml'

#revert test changes
yq eval -i '.type = "library"' library/Chart.yaml
