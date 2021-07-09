#!/usr/bin/env bash

set -e

helm lint library/

#change library chart to application
yq eval -i '.type = "application"' library/Chart.yaml

for version in $(echo "v2"); do
  for file in $(echo "hpa.yaml secretproviderclass.yaml secretproviderclass-tests.yaml deployment.yaml configmap.yaml ingress.yaml pdb.yaml service.yaml deployment-tests.yaml sa.yaml"); do
    cp tests/$version/$file library/templates/
    helm template release-name library -f ci-values.yaml > $file

    diff -w $file tests/results/$file
    
    #Language specific test
    helm template release-name library -f ci-values-lang.yaml > $file
    diff -w $file tests/results/$file

    rm -rf library/templates/$file $file
  done
done

#revert test changes
yq eval -i '.type = "library"' library/Chart.yaml
