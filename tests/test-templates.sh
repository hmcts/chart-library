#!/usr/bin/env bash

set -e

helm lint library/

#change library chart to application
yq w -i library/Chart.yaml type application

for file in $(echo "hpa.yaml secretproviderclass.yaml deployment.yaml configmap.yaml ingress.yaml pdb.yaml service.yaml deployment-tests.yaml sa.yaml"); do
  cp tests/v1/$file library/templates/
  helm template library -f ci-values.yaml > template-$file
  yq compare template-$file tests/results/template-$file
  rm -rf library/templates/$file template-$file
done

#revert test chabges
yq w -i library/Chart.yaml type library