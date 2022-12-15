#!/bin/bash

set -e

oc new-project ansible-ees

oc create secret generic pull-and-push \
  --from-file=.dockerconfigjson=/run/user/1000/containers/auth.json \
  --type=kubernetes.io/dockerconfigjson

oc secret link pipeline pull-and-push --for=pull,mount

oc create secret generic ansible-ee-trigger-secret \
  --from-literal secretToken=123

oc apply -f https://raw.githubusercontent.com/jwerak/catalog/main/task/ansible-builder/0.2/ansible-builder.yaml

oc -n ansible-ees apply -f ./listener

echo "Setup GithHub websocket for url: http://"`oc -n ansible-ees get route ansible-ee-el -o jsonpath="{.spec.host}"`
