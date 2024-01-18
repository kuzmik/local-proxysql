#!/bin/bash
set -eou pipefail

# Script to connect to the proxysql database, served via proxysql, via mysql, without execing into the pod

mysql_info=$(kubectl get service -n proxysql proxysql-satellite --output=json | jq -r '.spec.clusterIP')
mysql_host=$(echo "$mysql_info" | awk 'NR==1')

echo ""
echo "==> Connecting to the proxysql coordination database (served by proxysql)"
echo ""

mysql -h"$mysql_host" -P6033 -uproxysql -pproxysql
