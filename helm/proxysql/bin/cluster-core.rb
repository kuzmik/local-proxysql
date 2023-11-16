#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'json'
require 'net/http'
require 'pathname'
require 'uri'

# query the k8s rest api and get a list of the pods in the core cluster
# returns a hash of { pod_ip => pod_hostname } for all the core pods
def get_pod_info
  directory = '/run/secrets/kubernetes.io/serviceaccount'
  namespace = File.read(Pathname.new("#{directory}/namespace").realpath)
  token = File.read(Pathname.new("#{directory}/token").realpath)

  uri = URI("https://kubernetes.default.svc/api/v1/namespaces/#{namespace}/pods")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.ca_file = Pathname.new("#{directory}/ca.crt").realpath.to_s

  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{token}" # Set the Authorization header

  response = http.request(request)

  unless response.is_a?(Net::HTTPSuccess)
    puts "Request failed with code: #{response.code}"
    puts "Error message: #{response.body}"
    exit 1
  end

  data = JSON.parse(response.body)
  items = data['items']

  # filter the pod info, and create a hash of { ip: hostname }
  # we're also sorting it, so that we can use it for hashing the checksum
  items.reject  { |pod| pod['metadata']['labels']['app.kubernetes.io/instance'] == 'proxysql-satellite' }
       .collect { |pod| { pod['status']['podIP'] => pod['metadata']['name'] } }
       .reduce({}, :merge)
       .sort
end

# take a pod info hash and create a string of sql commands to use in proxysql
def create_commands(pods)
  output = ['DELETE FROM proxysql_servers']

  pods.each do |pi|
    output.append "INSERT INTO proxysql_servers VALUES ('#{pi[0]}', 6032, 0, '#{pi[1]}')"
  end

  output.append 'LOAD PROXYSQL SERVERS TO RUNTIME'
  output.append 'LOAD MYSQL VARIABLES TO RUNTIME'
  output.append 'LOAD MYSQL SERVERS TO RUNTIME'
  output.append 'LOAD MYSQL USERS TO RUNTIME'
  output.append 'LOAD MYSQL QUERY RULES TO RUNTIME'
  output.append 'SAVE PROXYSQL SERVERS TO DISK;'

  output.join('; ')
end

# take a checksum of the pod_info hash; the hash is sorted in the get_pod_info method,
# just in case the pods ever get returned in a different order
def checksum(pods)
  checksum_file = '/tmp/pods-cs.txt'

  digest = Digest::SHA256.hexdigest(pods.to_s)

  unless File.exist?(checksum_file)
    # write checksum to file for next run
    File.write(checksum_file, digest)
    return
  end

  old = File.read(checksum_file)

  # if there are no changes in the commands that would be run, run one command and exit 0
  # this command should help satellites rejoin the cluster if case the core pods all went away at once and came back
  if old == digest
    system('mysql -h127.0.0.1 -P6032 -uadmin -padmin -NB -e"LOAD PROXYSQL SERVERS TO RUNTIME;"')
    exit 0
  end

  # write checksum to file for next run
  File.write(checksum_file, digest)
end

pods = get_pod_info

checksum(pods)

commands = create_commands(pods)

system("mysql -h127.0.0.1 -P6032 -uadmin -padmin -NB -e\"#{commands}\"")
puts "Ran commands: #{commands}"
