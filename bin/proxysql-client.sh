#!/bin/bash
set -eou pipefail

# Script to connect to one of the satellite pods, as a client. ie: simulates a normal rails connection

DIR=$(dirname -- "${BASH_SOURCE[0]}")

proxysql_instance=$(kubectl get service proxysql-satellite -n proxysql --output jsonpath='{.spec.clusterIP}')

echo ""
echo "Connecting to MySQL - US1 Primary"
echo ""

mysql --defaults-extra-file="$DIR/.lib/us1-client.cfg" -h"$proxysql_instance" -P6033 --comments persona-web-us1
