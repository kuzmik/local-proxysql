#!/bin/bash
set -eou pipefail

# if we aren't in one of the orbstack/docker-desktop contexts, bail out. basically i want to prevent accidentally deploying
# this stuff to staging (or god help us, prod).
context=$(kubectl config current-context)
if [[ "$context" != "orbstack" ]] && [[ "$context" != "docker-desktop" ]]; then
  echo "You are not in the right kube context, current context is: $context. We want 'orbstack' or 'docker-desktop'"
  exit 1
fi

# Build the customized (sorta) ProxySQL docker image
pushd helm/proxysql
  docker build -t proxysql .
popd

# Create the mysql infra

## Create the MySQL namespace, unless it already exists
kubectl get namespace mysql > /dev/null 2>&1 \
  || kubectl create ns mysql

## Create some Configmaps that hold the MySQL init scripts, if they don't already exist
kubectl get configmap -n mysql us1-initdb > /dev/null 2>&1 \
  || kubectl create configmap -n mysql us1-initdb --from-file=./helm/data/mysql-us1.sql
kubectl get configmap -n mysql us2-initdb > /dev/null 2>&1 \
  || kubectl create configmap -n mysql us2-initdb --from-file=./helm/data/mysql-us2.sql

## Install the MySQL us1 and us2 instances, each of which has 1 replica
helm install mysql-us1 -n mysql ./helm/mysql \
  --set nameOverride="mysql-us1" \
  --set architecture="replication" \
  --set auth.rootPassword="rootpw" \
  --set auth.replicationPassword="replication" \
  --set auth.database="persona-web-us1" \
  --set auth.username="persona-web-us1" \
  --set auth.password="persona-web-us1" \
  --set initdbScriptsConfigMap="us1-initdb"

helm install mysql-us2 -n mysql ./helm/mysql \
  --set nameOverride="mysql-us2" \
  --set architecture="replication" \
  --set auth.rootPassword="rootpw" \
  --set auth.replicationPassword="replication" \
  --set auth.database="persona-web-us2" \
  --set auth.username="persona-web-us2" \
  --set auth.password="persona-web-us2" \
  --set initdbScriptsConfigMap="us2-initdb"

# End MySQL

echo "Sleeping 10s to allow mysql to finish coming up"
sleep 10

# Create the ProxySQL infra

## Create the ProxySQL namespace, unless it already exists
kubectl get namespace proxysql > /dev/null 2>&1 \
  || kubectl create ns proxysql

## ProxySQL leader cluster, which manages the configuration state of the rest of the cluster
helm install proxysql-core -n proxysql ./helm/proxysql/core

## ProxySQL main cluster, which will be serving the actual proxied sql traffic
helm install proxysql-satellite -n proxysql ./helm/proxysql/satellite

# End ProxySQL infra
