#!/usr/bin/env ruby
#
# This script is designed to fill in a gap for which I haven't found a 
# better way.
#
# Good News!  The better way is right here:
# puppet query 'nodes['certname']{! certname in resources['certname']{type="Class" and title~"[Rr]ole"}}'
#
# To use, replace the rbac_token and puppetdb_url with appropriate 
# values for your environment.
#
# This script is as is, no warranty or garuantee of fitness for 
# any purpose.
#
# 08-07-2018 Bill Wilcox - Initial design
# 08-08-2018 Bill Wilcox - Added the puppet query one-liner in the notes.
#
require 'httparty'
require 'multi_xml'

rbac_token = '0MoGYsLnCjA5uVEbm3aVr0ATi6OXA_WPUPMvW16nDvEY'
puppetdb_url = 'https://192.168.50.4:8081'
@all_nodes = []
@role_nodes = []

api_headers = {
    "X-Authentication" => "#{rbac_token}",
}

# Get a list of all the nodes in the system
node_query = CGI.escape('["extract", ["certname"], ["~", "certname", ".+"]]')
response = HTTParty.get(
    "#{puppetdb_url}/pdb/query/v4/inventory?query=#{node_query}",
    :verify => false,
    :headers => api_headers,
    )

response.body.tr('[]','').split(',').each do |x|
    @all_nodes << x.split('":"')[1].tr('"}', '')
end

# Get nodes which have a role class assigned
node_query = CGI.escape('[ "extract", "certname",[ "and", ["=", "type", "Class"], ["~", "title", "Role"]]]]')
response = HTTParty.get(
    "#{puppetdb_url}/pdb/query/v4/resources?query=#{node_query}",
    :verify => false,
    :headers => api_headers,
    )

response.body.tr('[]','').split(',').each do |x|
    @role_nodes << x.split('":"')[1].tr('"}', '')
end

# For debugging purposes
#puts @all_nodes.inspect
#puts @role_nodes.inspect

# finally, subtrack the role nodes from all nodes and what we have
# left are the nodes which don't have a role assigned.

puts (@all_nodes - @role_nodes).inspect
