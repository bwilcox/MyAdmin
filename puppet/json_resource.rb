#!/usr/bin/env ruby

require 'json'

load = '/Users/bill.wilcox/projects/FannieMae/logs/2019-11-19-1435-puppet-query.log'
counter = 0
total = 0

breakout = {
  'small' => 0, 
  'medium' => 0, 
  'large' => 0, 
}

contents = File.open(load, 'r')
contents.each_line do |line|
  if line =~ /count/
    counter += 1
    res_count = line.split[1].to_i
    if res_count < 200
      breakout['small'] += 1
    elsif (res_count > 200) && (res_count < 1000)
      breakout['medium'] += 1
    elsif (res_count > 1001)
      breakout['large'] += 1
    end
    total += line.split[1].to_i
  end
end

puts "Servers: #{counter}"
puts "Resources Assigned: #{total}"
puts "Resource Average: #{total/counter}"
puts "Distribution: #{breakout.inspect}"