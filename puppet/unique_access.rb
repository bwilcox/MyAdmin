#!/usr/bin/env ruby
#
# The point of this script is to parse a puppetserver log.  We're looking 
# for instances of 'store report' which indicates that an agent has completed
# a puppet run and has sent its report back to the master.
#
# In a default configuration, we expect the agents to checking every 30
# minutes.  So in a 30 minute time period we should only see each agent
# once.  Agents which show up more than once indicate that puppet is
# being run more by an external force.  
#
# Ad hoc puppet runs constitute additional load on the infrastructure
# and should be factored into sizing.
#
# 11-26-19 Bill W. - Initial version.
# 12-02019 Bill W. - Refinements to make it nicer to run.
#

require 'date'
require 'optparse'

options = {}
options[:quiet] = false

OptionParser.new do |opts|
  opts.banner = "Usage: unique_access.rb [options]"

  opts.on("-l", "--log=STRING", "Puppetserver log file to parse") do |f|
    options[:log] = f
  end

  opts.on("-o", "--output=STRING", "Output file for data") do |o|
    options[:output] = o
  end

  opts.on("-q", "Do not output results to the console.") do
    options[:quiet] = true
  end

  opts.on('-h', "--help", "Print the help") do
    puts opts
    exit
  end

end.parse!

# Make sure our input file is real.
unless File.exist?(options[:log])
  puts "ERROR Log file #{options[:log]} does not exist."
  exit
end

unless options[:quiet]
  puts "Processing #{options[:log]}..."
end

contents = File.open(options[:log], 'r')
servers = Array.new
checkins = Hash.new
contents.each_line do |line|
  if line =~ /store report/
    server = line.split[-1]
    date = DateTime.parse(line.split[0])
    date_line = "#{date.year}-#{date.month}-#{date.day}T"
    if (0..29).include?(date.min)
      unless checkins.key?("#{date_line}#{date.hour}:00")
        checkins.store("#{date_line}#{date.hour}:00", {})
      end
      if checkins["#{date_line}#{date.hour}:00"].key?(server)
        checkins["#{date_line}#{date.hour}:00"][server] += 1 
      else
        checkins["#{date_line}#{date.hour}:00"].store(server, 1) 
      end
    else
      unless checkins.key?("#{date_line}#{date.hour}:30")
        checkins.store("#{date_line}#{date.hour}:30", {})
      end
      if checkins["#{date_line}#{date.hour}:30"].key?(server)
        checkins["#{date_line}#{date.hour}:30"][server] += 1 
      else
        checkins["#{date_line}#{date.hour}:30"].store(server, 1) 
      end
    end

    unless servers.include?(server)
      servers << server
    end
  end
end

unless options[:quiet]
  puts "Found #{servers.length} unique servers."
  puts "Timestamp,Unique_Servers,Reports_Stored"
  checkins.each do | key, data |
    num_servers = data.keys.length
    total_checks = 0
    data.each do | x, y |
      total_checks += y.to_i
    end
    puts "#{key},#{num_servers},#{total_checks}"
  end
end

if options[:output]
  outfile = File.new(options[:output], 'w')
  outfile.write "Found #{servers.length} unique servers.\n"
  outfile.write "Timestamp,Unique_Servers,Reports_Stored\n"
  checkins.each do | key, data |
    num_servers = data.keys.length
    total_checks = 0
    data.each do | x, y |
      total_checks += y.to_i
    end
    outfile.write "#{key},#{num_servers},#{total_checks}\n"
  end
end
