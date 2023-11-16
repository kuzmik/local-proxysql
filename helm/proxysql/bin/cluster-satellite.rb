#!/usr/bin/env ruby
# frozen_string_literal: true

# count the number of proxysql servers that:
#   - are not named "proxysql-core" because that is the default server that is loaded from the config,
#     either on boot or by this script
#   - haven't been seen in over 30s (last_check_ms)
#   - have an uptime > 0
#     - when a satellite first joins the cluster, and before the core propagates config, last_check_ms
#       will continue to grow but uptime will remain 0
missing_command = "SELECT count(hostname) FROM stats_proxysql_servers_metrics WHERE last_check_ms > 30000 and hostname != 'proxysql-core' and Uptime_s > 0"
all_command = 'SELECT count(hostname) FROM stats_proxysql_servers_metrics'

missing_count = `mysql -h127.0.0.1 -P6032 -uadmin -padmin -NB -e"#{missing_command}"`.to_i
all_count = `mysql -h127.0.0.1 -P6032 -uadmin -padmin -NB -e"#{all_command}"`.to_i

# if there are any servers that are returned by the command, the entire core cluster is probably down; it was either
# removed, or has been deployed recently and got different IPs. because we aren't using static IPs, we want to bootstrap
# the proxysql servers again. joining the cluster will pull down data from the core pods automatically, though it tends to
# take ~20 seconds or so once the core pods come back online
if missing_count > 0
  puts "#{missing_count}/#{all_count} proxysql core pods haven't been seen in over 30s, resetting cluster state"

  commands = [
    'DELETE FROM proxysql_servers',
    'LOAD PROXYSQL SERVERS FROM CONFIG',
    'LOAD PROXYSQL SERVERS TO RUNTIME'
  ].join('; ')

  `mysql -h127.0.0.1 -P6032 -uadmin -padmin -NB -e"#{commands}"`
end
