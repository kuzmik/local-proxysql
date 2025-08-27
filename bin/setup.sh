#!/bin/bash
set -eou pipefail

# if we aren't in one of the orbstack/docker-desktop contexts, bail out. basically i want to prevent accidentally deploying
# this stuff to staging (or god help us, prod).
context=$(kubectl config current-context)
if [[ "$context" != "orbstack" ]] && [[ "$context" != "docker-desktop" ]] && [[ "$context" != "minikube" ]]; then
  echo "You are not in the right kube context, current context is: $context. We want 'orbstack' or 'docker-desktop'"
  exit 1
fi

DIR=$(dirname -- "${BASH_SOURCE[0]}")

# Create the mysql infra

## Create the MySQL namespace, unless it already exists
kubectl get namespace mysql > /dev/null 2>&1 \
  || kubectl create ns mysql

## US1
kubectl get configmap -n mysql us1-initdb > /dev/null 2>&1 \
  || kubectl create configmap -n mysql us1-initdb --from-file="$DIR/../helm/data/mysql-us1.sql"

helm install mysql-us1 -n mysql "$DIR/../helm/mysql" \
  --set nameOverride="mysql-us1" \
  --set architecture="replication" \
  --set auth.rootPassword="rootpw" \
  --set auth.replicationPassword="replication" \
  --set auth.database="web-us1" \
  --set auth.username="web-us1" \
  --set auth.password="web-us1" \
  --set initdbScriptsConfigMap="us1-initdb"

## US2
# kubectl get configmap -n mysql us2-initdb > /dev/null 2>&1 \
#   || kubectl create configmap -n mysql us2-initdb --from-file="$DIR/../helm/data/mysql-us2.sql"

# helm install mysql-us2 -n mysql "$DIR/../helm/mysql" \
#   --set nameOverride="mysql-us2" \
#   --set architecture="replication" \
#   --set auth.rootPassword="rootpw" \
#   --set auth.replicationPassword="replication" \
#   --set auth.database="web-us2" \
#   --set auth.username="web-us2" \
#   --set auth.password="web-us2" \
#   --set initdbScriptsConfigMap="us2-initdb"

# End MySQL infra

echo "Sleeping for 20s to allow mysql to finish coming up"
sleep 20

# Create the ProxySQL infra

## Create the ProxySQL namespace, unless it already exists
kubectl get namespace proxysql > /dev/null 2>&1 \
  || kubectl create ns proxysql

## ProxySQL leader cluster, which manages the configuration state of the rest of the cluster
helm install proxysql-core -n proxysql "$DIR/../helm/proxysql/core" # --set agentSidecar.enabled=false # FIXME

echo "Sleeping for 5s to allow core to finish coming up"
sleep 5

## ProxySQL main cluster, which will be serving the actual proxied sql traffic
helm install proxysql-satellite -n proxysql "$DIR/../helm/proxysql/satellite" # --set agentSidecar.enabled=false # FIXME

# End ProxySQL infra
