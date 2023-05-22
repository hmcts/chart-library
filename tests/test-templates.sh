#!/usr/bin/env bash

set -e

helm lint library/ --values ci-values.yaml

#change library chart to application
yq eval -i '.type = "application"' library/Chart.yaml

helm unittest -v ci-values.yaml library -q -f 'tests/snapshot-tests/*.yaml'
helm unittest -v ci-values-lang.yaml library -q -f 'tests/snapshot-tests/*.yaml'

helm unittest -v ci-values.yaml library -q -f 'tests/unit-tests/*.yaml'
helm unittest -v ci-values-lang.yaml library -q -f 'tests/unit-tests/*.yaml'

#revert test changes
yq eval -i '.type = "library"' library/Chart.yaml
