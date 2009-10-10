#!/usr/local/bin/ruby
#
# framework for a threaded script
# 
# 17-03-2009 Bill W. Trying to replicate dsh

# Addition ruby gems we need
require 'rubygems'
require 'optparse'
require 'ostruct'
require 'timeout' # Only if using the Timeout functions
require 'net/ssh' # Only if using ssh to execute remote commands
require '/users/mis/wilcbil/scripts/lib/serverbase.rb' # Provides ping/ssh/os checks
include BaseServerInfo

# Variables for the script run
version = 0.1
@serverlist = []
@command = String.new
qsize = 30
options = OpenStruct.new
options.list = []
options.command = String.new

# An array to hold thread ID's so we know what sub-threads we 
# should wait for.
threads = []

#### MAIN ####

# Pull out command line options and set the appropriate variables
OptionParser.new do |opts|
  opts.banner = "Useage : dsh [options]"

  opts.on("-l [a,b,c,...]", Array, "Server list, comma separated.") do |list|
    options.list = list 
  end
  opts.on("-f \"Server List File\"", String, "Server list file, one server per line") do |cmnd|
    options.file = cmnd 
  end
  opts.on("-c \"command to run\"", String, "Command to run") do |cmnd|
    options.command = cmnd 
  end
  opts.on_tail("-h", "-?", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.on_tail("-v", "--version", "Show version") do
    puts "dsh.rb version: #{version}"
    exit
  end

end.parse! # Optionparser

# Timer for the curious
tstart = Time.now

# List of servers
if options.file then
  lines = File.open("#{options.file}", "r")
  lines.each do |line|
    @serverlist << line.strip!
  end
else
  @serverlist = options.list
end


# Create the work queue for threading
@workqueue = SizedQueue.new(qsize)

# This object should keep track of all thread this script spawns.
def join_all
  main = Thread.main
  current = Thread.current
  all = Thread.list
  all.each { |t| t.join unless t == current or t == main }
end

# This object takes jobs out of the queue when they are done
def popper
    @workqueue.deq
end

#
# Start custom functions
#

def command_run(server, command)
  Net::SSH.start(server, 'root', :paranoid => false, :timeout => 10, :auth_methods => "publickey" ) do |ssh|
    stdout = ""
    ssh.exec!(command) do |channel, stream, data|
      stdout << data if stream == :stdout
    end
    return stdout
  end # ssh
end

def banner(text)
  puts "\n"
  puts "\#".*80
  puts "\#" + "#{text}".center(78) + "\#"
  puts "\#".*80
  puts "\n"
end # banner


#
# START Main Program
#

# This is the thread that spins up the sub-threads.  Because 
# SizedQueue blocks when the queue is full, we need the sub-threads
# and the popper function to dequeue them as they finish.
#worker = Thread.new {
#  @serverlist.each do |line|
#    @workqueue << Thread.new(line) { |l| 
      # 
      #  START Code to be threaded
      #
banner("Executing: #{options.command}")

@serverlist.each do |server|
  begin
    PingCheck(server) == "Good" && SShCheck(server) == "Good"
    output = command_run(server, options.command)
    banner(server)
    puts output
  rescue Timeout::Error
    banner(server)
    puts "Request Timed Out."
  rescue => ex
    banner(server)
    puts "ERROR - #{ex.class}: #{ex.message}"
  end
end


      # 
      #  END Code to be threaded
      #

      # Start a new thread to dequeue the worker when done
      # Should follow most if not all of the app logic
#      threads << Thread.new {popper}
#    } 
#  end  # line processing

  #  This causes the worker thread to wait for all sub-threads to 
  # exit before continuing.
#  threads.each { |t| t.join }
#}

# This waits for the main worker thread to finish before continuing. 
#worker.join
#join_all

# Just some time arithmetic to measure how long we ran
tstop = Time.now
ttime = tstop - tstart

banner("End Remote Command Execution")

puts "Script finished in " + ttime.to_s + " seconds."

