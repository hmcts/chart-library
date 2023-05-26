#!/usr/bin/env bash

set -e

helm lint library/ --values ci-values.yaml
helm unittest --help

#change library chart to application
yq eval -i '.type = "application"' library/Chart.yaml

helm unittest --values ci-values.yaml library -q -f 'tests/snapshot-tests/*.yaml'
helm unittest --values ci-values-lang.yaml library -q -f 'tests/snapshot-tests/*.yaml'

helm unittest --values ci-values.yaml library -q -f 'tests/unit-tests/*.yaml'
helm unittest --values ci-values-lang.yaml library -q -f 'tests/unit-tests/*.yaml'

#revert test changes
yq eval -i '.type = "library"' library/Chart.yaml
