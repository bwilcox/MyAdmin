#!/usr/bin/env ruby
#
# Build a large number of groups.
require 'httparty'
require 'uri'
require 'json'
require 'benchmark'

rbac_token = '0Gh7oPAcE-5saPbmyMnyQ3ZisetLTGhH67y41h0WFG_s'
console_api = 'https://master.vm:4433/classifier-api/v1/groups'
group_id = 'dade3d16-b0f1-4d85-9446-1ff4e095457d'
num_nodes = 100

def gen_nodes
  list = Array.new
  list << "or"
  i = 1
  for i in 1..5000 do
    list << ["=", "name", "buster#{i}"]
    i+=1
  end
  return list
end

api_headers = {
  "X-Authentication" => "#{rbac_token}",
  "Content-Type" => "application/json",
}

puts "Time spent generating node list"
puts Benchmark.measure {
  @node_list = gen_nodes
}

#puts node_list.inspect

node_query = JSON.generate({ "rule": @node_list })

uri = URI("#{console_api}/#{group_id}")

puts "Time spent on database operation"
puts Benchmark.measure {
  response = HTTParty.post(
    "#{console_api}/#{group_id}",
    :verify => false,
    :headers => api_headers,
    :body => node_query,
  )
}

#puts response.inspect

puts "Time spent getting the node group"
puts Benchmark.measure {
  response = HTTParty.get(
    "#{console_api}/#{group_id}",
    :verify => false,
    :headers => api_headers,
  )
}
