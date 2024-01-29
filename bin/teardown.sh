#!/bin/bash
set -eou pipefail

# if we aren't in one of the orbstack/docker-desktop contexts, bail out. basically i want to prevent accidentally un-deploying
# this stuff to staging (or god help us, prod).
context=$(kubectl config current-context)
if [[ "$context" != "orbstack" ]] && [[ "$context" != "docker-desktop" ]] && [[ "$context" != "minikube" ]]; then
  echo "You are not in the right kube context, current context is: $context. We want 'orbstack' or 'docker-desktop'"
  exit 1
fi

helm uninstall -n proxysql --ignore-not-found proxysql-core
helm uninstall -n proxysql --ignore-not-found proxysql-satellite

helm uninstall -n mysql --ignore-not-found mysql-us1
helm uninstall -n mysql --ignore-not-found mysql-us2
helm uninstall -n mysql --ignore-not-found proxysql

# Probably all we _really_ need to do here is delete the namespaces, but then helm might get confused
kubectl delete ns --ignore-not-found proxysql
kubectl delete ns --ignore-not-found mysql
