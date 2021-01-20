#!/usr/bin/env bash

set -e

helm lint library/

#change library chart to application
yq eval -i '.type = "application"' library/Chart.yaml

for version in $(echo "v1 v2"); do
  for file in $(echo "hpa.yaml secretproviderclass.yaml deployment.yaml configmap.yaml ingress.yaml pdb.yaml service.yaml deployment-tests.yaml sa.yaml"); do
    cp tests/$version/$file library/templates/
    helm template library -f ci-values.yaml > $file
    
    # sort yamls before compare
    yq eval -i 'sortKeys(..)' $file
    yq eval -i 'sortKeys(..)' tests/results/$file
    
    diff -w $file tests/results/$file
    rm -rf library/templates/$file $file
  done
done

#revert test changes
yq eval -i '.type = "library"' library/Chart.yaml