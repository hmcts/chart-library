#!/usr/bin/env bash

set -e

sudo snap install yq

helm lint library/

#copy test deployment
cp tests/{deployment.yaml,configmap.yaml,ingress.yaml,pdb.yaml,service.yaml} library/templates/

#change library chart to application
yq w -i library/Chart.yaml type application

version=$(yq r library/Chart.yaml version)

sed -i "s/{chartVersion}/$version/g" tests/deployment-template.yaml 

helm template library -f ci-values.yaml > deployment-template.yaml

yq compare deployment-template.yaml tests/deployment-template.yaml

#revert test chabges
yq w -i library/Chart.yaml type library
rm -rf library/templates/deployment.yaml