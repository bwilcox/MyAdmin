#!/usr/bin/env ruby

require 'json'

load = '/Users/bill.wilcox/projects/FannieMae/logs/1107logs/enterprise/puppetdb_nodes.json'
contents = File.open(load, 'r')
contents.each_line do |line|
  puts JSON.parse(line).length
end

