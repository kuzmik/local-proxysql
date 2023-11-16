#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'

##
# Class to handle the pre-stop signal from k8s. Intended to pause ProxySQL and allow traffic to drain, hopefully
# reducing the number of 503 errors rails throws due to connection issues
class PreStop
  # Script will sleep for READINESS_STATE_DELAY seconds after touching `/tmp/draining`, in order to allow the k8s
  # service time to remove the pod from EndpointSlices
  READINESS_STATE_DELAY = 10

  # PRE_KILL_BUFFER gives the script a little extra buffer time to wrap things up.
  PRE_KILL_BUFFER = 4

  # Hash that holds the configuration options for the script. Pared down, so it only really includes :verbose
  # and :shutdown_delay now
  attr_reader :options

  ##
  # Initializer
  #
  # @param [Hash<key, value>] options hash of options, from OptParse
  def initialize(options)
    @options = options

    raise 'Missing shutdown delay' unless options[:shutdown_delay]

    delay = @options[:shutdown_delay] - READINESS_STATE_DELAY - PRE_KILL_BUFFER
    delay = 15 unless delay.positive?

    @options[:shutdown_delay] = delay

    stop
  end

  ##
  # Wrapper method that calls all the necessary pausing functions and handles the sleeping.
  # Steps taken:
  #   1. sleep READINESS_STATE_DELAY seconds to allow some time for the Service to remove the pod from EndpointSlices
  #   2. disable new connections to proxysql, while allowing existing connections to drain
  #   3. sleep @options[:shutdown_delay] seconds (which should be equal to the containers's TerminationGracePeriod - READINESS_STATE_DELAY - PRE_KILL_BUFFER)
  #   4. exit
  def stop
    # [tag:prestop_draining] Touch the draining file, which [ref:probes_draining] probes.rb uses to determine that even
    # if checks would return unhealthy, they should pass.
    FileUtils.touch('/tmp/draining')

    puts "#{ENV.fetch('HOSTNAME', nil)} - ProxySQL pre-stop - Created /tmp/draining, sleeping for #{READINESS_STATE_DELAY} seconds"
    sleep READINESS_STATE_DELAY

    disable_new_connections

    puts "#{ENV.fetch('HOSTNAME', nil)} - ProxySQL pre-stop - Connections disabled, sleeping for #{@options[:shutdown_delay]} before exit"

    # sleep to prevent the script from exiting, which will kill the container immediately
    sleep @options[:shutdown_delay]
  end

  ##
  # This method will pause ProxySQL, which prevents new connections from being made. It will then start the process of
  # draining current connections, sleeping for {@options[:shutdown_delay]} seconds to allow any inflight transactions to
  # wrap up. If any txns are still in progress when the sleep expires, the container will be killed and they will be severed.
  #
  # MySQL variables modified by this method:
  # {connection_max_age_ms}[https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-connection_max_age_ms]::
  #    When mysql-connection_max_age_ms is set to a value greater than 0, inactive connections in the connection pool
  #    (therefore not currently used by any session) are closed if they were created more than mysql-connection_max_age_ms
  #    milliseconds ago. By default, connections aren’t closed based on their age. When mysql-connection_max_age_ms is
  #    reached, connections are simply disconnected, without sending COM_QUIT command to the server, so this might result
  #    in Aborted connection warnings showing up in your MySQL server logs (this behaviour is intended)
  #
  # {max_transaction_time}[https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-max_transaction_time]::
  #    Sessions with active transactions running more than this timeout are killed.
  #
  # {wait_timeout}[https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-wait_timeout]::
  #    If a proxy session (which is a conversation between a MySQL client and a ProxySQL) has been idle for more than
  #    this threshold, the proxy will kill the session.
  def disable_new_connections
    commands = [
      "UPDATE global_variables SET variable_value = #{(@options[:shutdown_delay] - 2) * 1000} WHERE variable_name = 'mysql-connection_max_age_ms'",
      "UPDATE global_variables SET variable_value = #{(@options[:shutdown_delay] - 2) * 1000} WHERE variable_name = 'mysql-max_transaction_time'",
      "UPDATE global_variables SET variable_value = 1 WHERE variable_name = 'mysql-wait_timeout'",
      'LOAD MYSQL VARIABLES TO RUNTIME',
      'PROXYSQL PAUSE;'
    ]

    puts "#{ENV.fetch('HOSTNAME', nil)} - ProxySQL pre-stop - Running mysql commands: #{commands.join('; ')}"

    # nosemgrep: ruby.lang.security.dangerous-subshell.dangerous-subshell
    `mysql -NB -e "#{commands.join('; ')}"`
  end
end

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: #{__FILE__} [options]"

  parser.on('-d', '--shutdown-delay SHUTDOWN_DELAY', Integer,
            'Required SHUTDOWN_DELAY: Integer number of seconds to wait for readiness to fail') do |shutdown_delay|
    options[:shutdown_delay] = shutdown_delay
  end
end.parse!

PreStop.new(options)

exit 0
