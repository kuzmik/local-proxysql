#!/bin/bash
set -eou pipefail

# small script to uninstall proxysql and reinstall it; this is useful for testing
# my proxysql-agent docker changes

# if we aren't in one of the orbstack/docker-desktop contexts, bail out. basically i want to prevent accidentally deploying
# this stuff to staging (or god help us, prod).
context=$(kubectl config current-context)
if [[ "$context" != "orbstack" ]] && [[ "$context" != "docker-desktop" ]]; then
  echo "You are not in the right kube context, current context is: $context. We want 'orbstack' or 'docker-desktop'"
  exit 1
fi

DIR=$(dirname -- "${BASH_SOURCE[0]}")

replicas=${1:-3}

helm uninstall -n proxysql --ignore-not-found proxysql-core
helm uninstall -n proxysql --ignore-not-found proxysql-satellite

helm install -n proxysql proxysql-core "$DIR/../helm/proxysql/core" --set replicaCount="$replicas"

echo "Sleeping 10s to allow core to finish coming up"
sleep 10

helm install -n proxysql proxysql-satellite "$DIR/../helm/proxysql/satellite" --set replicaCount="$replicas"
