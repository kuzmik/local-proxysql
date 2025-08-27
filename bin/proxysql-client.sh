#!/bin/bash
set -eou pipefail

# Script to connect to one of the satellite pods, as a client. ie: simulates a normal rails connection

DIR=$(dirname -- "${BASH_SOURCE[0]}")

proxysql_instance=proxysql-satellite.proxysql.svc.cluster.local

echo ""
echo "==> Connecting to the us1 primary database (served by proxysql)"
echo ""

mysql --defaults-extra-file="$DIR/.lib/us1-client.cfg" -h"$proxysql_instance" -P6033
