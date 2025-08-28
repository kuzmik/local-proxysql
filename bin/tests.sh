#!/bin/bash
set -eou pipefail

DIR=$(dirname -- "${BASH_SOURCE[0]}")

source "$DIR/.lib/assert.sh"

proxysql_instance=$(kubectl get service proxysql-satellite -n proxysql --output jsonpath='{.spec.clusterIP}')

###
log_header "us1 primary"

us1_hostname=$(mysql --defaults-extra-file="$DIR/.lib/us1-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@hostname')
assert_eq "mysql-us1-primary-0" "$us1_hostname" "Not equivalent"
log_success  "us1_primary hostname: mysql-us1-primary-0 == $us1_hostname"

us1_primary_ro=$(mysql --defaults-extra-file="$DIR/.lib/us1-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@global.read_only')
assert_eq "0" "$us1_primary_ro" "Not equivalent"
log_success  "us1_primary readonly flag: 0 == $us1_primary_ro"

us1_user=$(mysql --defaults-extra-file="$DIR/.lib/us1-client.cfg"  -h"$proxysql_instance" -P6033  web-us1 -NB -e 'select email from users where id = 1')
assert_eq "rick@us1.com" "$us1_user" "Not equivalent"
log_success "us1_primary user: rick@us1.com == $us1_user"

###
log_header "us1 replica0"

us1_ro_hostname=$(mysql --defaults-extra-file="$DIR/.lib/us1-ro0-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@hostname')
assert_eq "mysql-us1-replica0-0" "$us1_ro_hostname" "Not equivalent"
log_success  "us1_replica0 hostname: mysql-us1-replica0-0 == $us1_ro_hostname"

us1_replica0_ro=$(mysql --defaults-extra-file="$DIR/.lib/us1-ro0-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@global.read_only')
assert_eq "1" "$us1_replica0_ro" "Not equivalent"
log_success  "us1_replica0 readonly flag: 1 == $us1_replica0_ro"

us1_replica0_user=$(mysql --defaults-extra-file="$DIR/.lib/us1-ro0-client.cfg"  -h"$proxysql_instance" -P6033  web-us1 -NB -e 'select email from users where id = 1')
assert_eq "rick@us1.com" "$us1_replica0_user" "Not equivalent"
log_success  "us1_replica0 user: rick@us1.com == $us1_replica0_user"

###
log_header "us1 replica1"

us1_replica1_hostname=$(mysql --defaults-extra-file="$DIR/.lib/us1-ro1-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@hostname')
assert_eq "mysql-us1-replica1-0" "$us1_replica1_hostname" "Not equivalent"
log_success  "us1_replica1 hostname: mysql-us1-replica1-0 == $us1_replica1_hostname"

us1_replica1_ro=$(mysql --defaults-extra-file="$DIR/.lib/us1-ro1-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@global.read_only')
assert_eq "1" "$us1_replica1_ro" "Not equivalent"
log_success  "us1_replica1 readonly flag: 1 == $us1_replica1_ro"

us1_replica0_user=$(mysql --defaults-extra-file="$DIR/.lib/us1-ro1-client.cfg"  -h"$proxysql_instance" -P6033  web-us1 -NB -e 'select email from users where id = 1')
assert_eq "rick@us1.com" "$us1_replica0_user" "Not equivalent"
log_success  "us1_replica1 user: rick@us1.com == $us1_replica0_user"

###
log_header "us2 primary"

us2_hostname=$(mysql --defaults-extra-file="$DIR/.lib/us2-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@hostname')
assert_eq "mysql-us2-primary-0" "$us2_hostname" "Not equivalent"
log_success  "us2_primary hostname: mysql-us2-primary-0 == $us2_hostname"

us2_primary_ro=$(mysql --defaults-extra-file="$DIR/.lib/us2-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@global.read_only')
assert_eq "0" "$us2_primary_ro" "Not equivalent"
log_success  "us2_primary readonly flag: 0 == $us2_primary_ro"

us2_user=$(mysql --defaults-extra-file="$DIR/.lib/us2-client.cfg"  -h"$proxysql_instance" -P6033  web-us2 -NB -e 'select email from users where id = 1')
assert_eq "charles@us2.com" "$us2_user" "Not equivalent"
log_success  "us2_primary user: charles@us2.com == $us2_user"

###
log_header "us2 replica0"

us2_ro_hostname=$(mysql --defaults-extra-file="$DIR/.lib/us2-ro1-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@hostname')
assert_eq "mysql-us2-replica0-0" "$us2_ro_hostname" "Not equivalent"
log_success  "us2_replica0 hostname: mysql-us2-replica0-0 == $us2_ro_hostname"

us2_replica0_ro=$(mysql --defaults-extra-file="$DIR/.lib/us2-ro1-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@global.read_only')
assert_eq "1" "$us2_replica0_ro" "Not equivalent"
log_success  "us2_replica0 readonly flag: 1 == $us2_replica0_ro"

us2_replica0_user=$(mysql --defaults-extra-file="$DIR/.lib/us2-ro1-client.cfg"  -h"$proxysql_instance" -P6033  web-us2 -NB -e 'select email from users where id = 1')
assert_eq "charles@us2.com" "$us2_replica0_user" "Not equivalent"
log_success  "us2_replica0 user: charles@us2.com == $us2_replica0_user"

###
log_header "us2 replica1"

us2_replica1_hostname=$(mysql --defaults-extra-file="$DIR/.lib/us2-ro2-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@hostname')
assert_eq "mysql-us2-replica1-0" "$us2_replica1_hostname" "Not equivalent"
log_success  "us2_replica1 hostname: mysql-us2-replica1-0 == $us2_replica1_hostname"

us2_replica1_ro=$(mysql --defaults-extra-file="$DIR/.lib/us2-ro2-client.cfg" -h"$proxysql_instance" -P6033 -NB -e 'select @@global.read_only')
assert_eq "1" "$us2_replica1_ro" "Not equivalent"
log_success  "us2_replica1 readonly flag: 1 == $us2_replica1_ro"

us2_replica1_user=$(mysql --defaults-extra-file="$DIR/.lib/us2-ro2-client.cfg"  -h"$proxysql_instance" -P6033  web-us2 -NB -e 'select email from users where id = 1')
assert_eq "charles@us2.com" "$us2_replica1_user" "Not equivalent"
log_success  "us2_replica1 user: charles@us2.com == $us2_replica1_user"


echo ''
log_success  '-*-*-*-*- all tests passed, insert emojis here -*-*-*-*-'
echo ''
