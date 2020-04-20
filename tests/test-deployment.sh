#!/usr/bin/env bash

set -e

sudo snap install yq

helm lint library/

#copy test deployment
cp tests/deployment.yaml library/templates/

#change library chart to application
sed -i "s/library/application/g" library/Chart.yaml

helm template library -f ci-values.yaml > deployment-template.yaml

yq compare deployment-template.yaml tests/deployment-template.yaml

#revert test chabges
sed -i "s/application/library/g" library/Chart.yaml
rm -rf library/templates/deployment.yaml