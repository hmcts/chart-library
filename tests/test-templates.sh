#!/usr/bin/env bash

set -e

helm lint library/

#change library chart to application
yq eval -i '.type = "application"' library/Chart.yaml

for file in $(echo "hpa.yaml secretproviderclass.yaml deployment.yaml configmap.yaml ingress.yaml pdb.yaml service.yaml deployment-tests.yaml sa.yaml"); do
  cp tests/$file library/templates/
  helm template library -f ci-values.yaml > template-$file
  diff template-$file tests/results/template-$file
  rm -rf library/templates/$file template-$file
done

#revert test chabges
yq eval -i '.type = "library"' library/Chart.yaml