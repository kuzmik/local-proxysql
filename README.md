# ProxySQL k8s Cluster for Replicated Databases

Since we run ProxySQL in k8s at work, I needed a test cluster that I could more easily iterate on. Obviously, this isn't exaclty what our real setup looks like, aside from maybe a few names (persona-web, etc), but it's close enough that I can test changes without affecting staging or prod.

This repo uses the [MySQL](https://github.com/bitnami/containers/tree/main/bitnami/mysql) helm charts from Bitnami to setup the mysql backends. The limitation here is we can only have one replica per primary, which doesn't really match our infra, but is good enough for now. In the future perhaps I will find another chart or modify this one to setup two replicas.

## Setup

This assumes you have a k8s cluster on hand; we're installing some helm charts into it. I'm just using orbstack as my local k8s cluster, but I don't think the implementation really matters a lot for this.

**Note**: the latest mysql in homebrew is [not compatible](https://github.com/sysown/proxysql/issues/4300) with the proxysql admin interface; you either need to use `mysql-client@8.0` or just exec into the contoller pods to access the mysql admin interface.

## ProxySQL Agent

We've gotten rid of the ruby tooling and we've moved to using the [proxysql-agent](https://github.com/persona-id/proxysql-agent) sidecar. The helm charts now pull the image from the ghcr.io registry, so no extra steps are needed here.

## TL;DR LET ME INNNNN

Run [./bin/setup.sh](./bin/setup.sh) to create the test infra:

1. A us1 mysql instance with one read only replica
1. A us2 mysql instance with one read only replica
1. A `proxysql-core` deployment consisting of 3 pods
    * This cluster controls the configuration of the rest of the cluster, and does not serve sql traffic
1. A `proxysql-satellite` deployment consisting of 3 pods
    * This cluster gets configuration from the core, and is what serves the sql traffic

### Create the MySQL cluster

We'll create one primary and one secondary mysql instance, and make sure they are replicating. We're using the bitnami mysql chart (and changing values on the command line) for this install.

*NB*: the mysql charts use PVCs, so don't be surprised when you uninstall/reinstall the chart and the mysql data hasn't reset itself. The [./bin/teardown.sh](./bin/teardown.sh) script will delete everything, if you want a fresh start.

```shell
kubectl get namespace mysql > /dev/null 2>&1 \
  || kubectl create ns mysql

kubectl get configmap -n mysql us1-initdb > /dev/null 2>&1 \
  || kubectl create configmap -n mysql us1-initdb --from-file=./helm/data/mysql-us1.sql
kubectl get configmap -n mysql us2-initdb > /dev/null 2>&1 \
  || kubectl create configmap -n mysql us2-initdb --from-file=./helm/data/mysql-us2.sql

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
```

### Create the ProxySQL cluster

For this step, we're creating a proxysql core statefulset cluster and a proxysql satellite deployment cluster. The core cluster is the "leader" and is in charge of distributing the configuration changes to the satellite cluster. The satellites are configured to automatically connect to the core service on boot.

If you want to just test proxysql changes, yuou can run [./bin/reset-proxysql.sh](./bin/reset-proxysql.sh) to reinstall it without having to sit thruogh a full teardown/setup. This is mostly useful when I am testing changes to the proxysql-agent docker image.

```shell
kubectl get namespace proxysql > /dev/null 2>&1 \
  || kubectl create ns proxysql

helm install proxysql-core -n proxysql ./helm/proxysql/core

helm install proxysql-satellite -n proxysql ./helm/proxysql/satellite
```

-----

## Creds

### MySQL - US1 shard

* database: persona-web-us1
* username: persona-web-us1
* password: persona-web-us1

### MySQL - US2 shard

* database: persona-web-us2
* username: persona-web-us2
* password: persona-web-us2

### To Connect to MySQL Directly

This connects to the database as root, using the root password k8s secret (which is just... `rootpw`). You can connect to any service avaiable in the mysql namespace, as long as they have a ClusterIP (ie: not the headless services).

```shell
mysql -h$(kubectl get services -n mysql mysql-us1-primary -o jsonpath='{.spec.clusterIP}') -uroot -prootpw persona-web-us1
```

There is the assumption here that you have the `mysql` command available; if not, you can use the docker image from bitnami:

```shell
kubectl run mysql-us2-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mysql:8.0.34-debian-11-r56 --namespace mysql --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash
```

### Connecting to MySQL Backends via ProxySQL

Connect to us1 or us2 via proxysql

```shell
mysql -h$(kubectl get service proxysql-satellite -n proxysql --output jsonpath='{.spec.clusterIP}') -P6033 -upersona-web-us1 -ppersona-web-us1 persona-web-us1

mysql -h$(kubectl get service proxysql-satellite -n proxysql --output jsonpath='{.spec.clusterIP}') -P6033 -upersona-web-us2 -ppersona-web-us2 persona-web-us2
```

-----

## Teardown

```shell
helm uninstall -n proxysql --ignore-not-found proxysql-core
helm uninstall -n proxysql --ignore-not-found proxysql-satellite

helm uninstall -n mysql --ignore-not-found mysql-us1
helm uninstall -n mysql --ignore-not-found mysql-us2

kubectl delete ns --ignore-not-found proxysql
kubectl delete ns --ignore-not-found mysql
```
