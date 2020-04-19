#!/usr/bin/env bash

set -e
cp tests/deployment.yaml library/templates/
sed -i "s/library/application/g" library/Chart.yaml
helm template library -f ci-values.yaml > deployment-template.yaml
sudo snap install yq
yq compare deployment-template.yaml tests/deployment-template.yaml
sed -i "s/application/library/g" library/Chart.yaml
rm -rf library/templates/deployment.yaml