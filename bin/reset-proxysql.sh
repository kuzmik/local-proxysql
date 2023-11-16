#!/bin/bash
set -eou pipefail

# small script to uninstall proxysql and reinstall it with 1 replcia each; this is useful for testing
# my proxysql-agent docker changes

helm uninstall -n proxysql --ignore-not-found proxysql-core
helm uninstall -n proxysql --ignore-not-found proxysql-satellite

helm install -n proxysql proxysql-core ./helm/proxysql/core --set replicaCount=1
helm install -n proxysql proxysql-satellite ./helm/proxysql/satellite --set replicaCount=1
