#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'logger'

# FIXME: this might need to change with the clustering, because at boot the satellite pods won't have mysql backends... until
# they get the info from the core pods. or maybe we just add a delay to the k8s probe

##
# Class that contains all of the ProxySQL related probes we want to run. Currently used for startup and readiness probes.
# File was adapted from {probe-proxysql.bash}[https://github.com/ProxySQL/kubernetes/blob/master/proxysql-cluster-passive/files/probe-proxysql.bash]
class Probes
  # Hash that contains the options passed in from OptParse. It's been pared down, so it only really holds :verbose now.
  attr_reader :options

  # Hash that holds the results of the checks
  attr_reader :results

  ##
  # Initializer
  #
  # @param [Hash<symbol, value>] options Hash passed in from OptParse
  def initialize(options)
    @options = options
    @results = {}

    @logger = Logger.new($stdout)

    run_checks
  end

  ##
  # Wrapper method that runs all the required checks and stores the results in {Probes#results}
  def run_checks
    @results[:backends_online] = backends_online?
    @results[:clients_online] = client_connections
    @results[:draining] = draining?

    @results[:status_code] = status_code

    if @options[:verbose]
      @logger.debug "Options: #{@options}"
      @logger.debug "Results: #{@results}"
      @logger.debug "Exit code: #{@results[:status_code]}"
    end

    puts "#{ENV.fetch('HOSTNAME', nil)} ProxySQL probe: #{@results.merge(@options)}"
  end

  ##
  # Checks for at least one backend server with status ONLINE; this verifies that ProxySQL is connected to backends.
  # This doesnn't test the health of the backends, just that ProxySQL is up and accepting connections for them.
  #
  # Potentially useful queries:
  #   select * from stats_mysql_global where variable_name in ('Client_Connections_connected', 'Active_Transactions');
  #
  # @return [true] if any backends are online
  def backends_online?
    online = `mysql -NB -e "select count(*) from runtime_mysql_servers where status = 'ONLINE'"`.strip.to_i
    total = `mysql -NB -e "select count(*) from runtime_mysql_servers"`.strip.to_i

    @results[:backends] = { online: online, total: total }

    @logger.info "Backend status: total=#{total}, online=#{online}" if @options[:verbose]

    # Return healthy if all at least one backend is online. In theory, we'd want this to be online == total,
    # but if one cloudsql instance were to go down due to maintenance or something, proxysql would go bad for ALL
    # connections, and that would be bad times.
    online.positive?
  end

  ##
  # Get a count of the current frontend connections to proxysql and store it in {#results}
  #
  # @return [Int] count of clients connected to the frontend
  def client_connections
    clients = `mysql -NB -e "select Client_Connections_connected from mysql_connections order by timestamp desc limit 1"`.to_i

    @logger.info "Frontend clients connected to proxysql: #{clients}" if @options[:verbose]

    clients
  end

  ##
  # Check to see if +/tmp/draining+ exists. This file is created by the pre-stop script to signal that the probes should
  # continue to pass, even though things might technically seem unhealthy
  #
  # @return [true] if any +/tmp/draining+ exists
  def draining?
    exists = File.exist?('/tmp/draining')

    if exists && @options[:verbose]
      @logger.warn 'Pod draining: /tmp/draining exists, the pod is draining traffic for the PreStop hook; all checks will return healthy'
    end

    exists
  end

  ##
  # Calculate and return the cumulative status code, for use in exiting the script
  #
  # @return [Int] status code
  def status_code
    status = 0

    status += 1 unless @results[:backends_online]
    status += 2 if @results[:draining]

    status
  end
end

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: #{__FILE__} [options]"

  parser.on('-v', '--verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end

  # these are here as no-ops because we got rid of the options, but the k8s checks still
  # call them. remove them we redeploy.
  # rubocop:disable Lint/EmptyBlock
  parser.on('-l') {}
  parser.on('-r') {}
  # rubocop:enable Lint/EmptyBlock
end.parse!

checks = Probes.new(options)

# exit with the sum of the checks as the status code, in case we wanted to get clever
exit checks.status_code
