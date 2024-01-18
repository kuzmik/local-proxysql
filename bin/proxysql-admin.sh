#!/bin/bash
set -eou pipefail

# Script to connect to the proxysql-core via mysql, without execing into the pod

mysql_info=$(kubectl get service -n proxysql proxysql-core --output=json | jq -r '.spec.clusterIP, .spec.ports[0].port')
mysql_host=$(echo "$mysql_info" | awk 'NR==1')
mysql_port=$(echo "$mysql_info" | awk 'NR==2')

echo ""
echo "==> Connecting to the proxysql admin interface on proxysql-core"
echo ""

mysql -h"$mysql_host" -P"$mysql_port" -uradmin -pradmin
