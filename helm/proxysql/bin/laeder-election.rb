#!/usr/bin/ruby

require 'net/http'
require 'json'
require 'pathname'

@directory = '/run/secrets/kubernetes.io/serviceaccount'
@k8s_api_url = 'https://kubernetes.default.svc'
@token = File.read(Pathname.new("#{@directory}/token").realpath)
@namespace = File.read(Pathname.new("#{@directory}/namespace").realpath)
@lease_name = 'leader-election-lease'


def create_or_renew_lease
  uri = URI("#{@k8s_api_url}/apis/coordination.k8s.io/v1/namespaces/#{@namespace}/leases/#{@lease_name}")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.ca_file = Pathname.new("#{@directory}/ca.crt").realpath.to_s

  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'application/json'
  #request['Authorization'] = "Bearer #{@token}" # Set the Authorization header

  response = http.request(request)

  if response.code == '200'
    lease = JSON.parse(response.body)
    lease['spec']['renewTime'] = Time.now.utc.iso8601
    request = Net::HTTP::Put.new(uri)
    request['Content-Type'] = 'application/json'
    #request['Authorization'] = "Bearer #{@token}" # Set the Authorization header
    request.body = lease.to_json

    response =  http.request(request)
  else
    lease_data = {
      kind: 'Lease',
      apiVersion: 'coordination.k8s.io/v1',
      metadata: {
        name: @lease_name,
        namespace: @namespace,
      },
      spec: {
        holderIdentity: 'my-leader',
        leaseDurationSeconds: 30,
      }
    }

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = lease_data.to_json

    response = http.request(request)
  end

  response
end


loop do
  lease_response = create_or_renew_lease
  puts lease_response.body

  if lease_response.code == '200' || lease_response.code == '201'
    puts 'I am the leader!'
  else
    puts 'Someone else is the leader.'
  end

  sleep(15)
end
