#!/usr/local/bin/ruby
#
# Takes in input file which is a list of mounts generated from the netapp
# and does the following:
#   1. Checks if the client server is pingable
#   2. Checks if the client server is sshable
#   3. Checks if the volume noted on the netapp is in the mount table on the client
#   4. Attempts a directory listing in the mount point on the client.
# If the directory listing takes longer than 30 seconds, it will time out and
# you will see a WARNING! message in the log.  You should probably check on that
# server.
#
# Multi-threaded, don't expect output to be in the order of the input file. It
# will be in the order of responses from the clients querried; first come, first
# served.
#
# The timeout function will leave process orphans on the client side. Orphan_assasin
# will remove them. 
# 
# 27-03-2009 Bill W. Initial program design

# Addition ruby gems we need
require 'rubygems'
require 'timeout'
require 'net/ssh'
require 'serverbase.rb' # Provides ping/ssh/os checks
include BaseServerInfo

# Variables for the script run
@inputdir = "/input/dir"
@outputdir = "/output/dir"
@inputfile = "input.txt"
@outputfile = "output.txt"
qsize = 30

#### MAIN ####

# Setup the log file
Dir.chdir(@outputdir)
if File.exists?(@outputfile) then
  # Rename
  suffix = Time.now
  File.rename(@outputfile, "#{@outputfile}.#{suffix.strftime("%X")}")
end # Check for existing output file

# Open the logfile for writing
@log = File.open(@outputfile, "w")

# Turned log buffering on otherwise threads stomp on each other
# writing to the log file.  Gets messy.
@log.sync = false

# Timer for the curious
tstart = Time.now

# Open the input file
@serverlist = File.open("#{@inputdir}/#{@inputfile}", "r")

# Create the work queue for threading
@workqueue = SizedQueue.new(qsize)

def orphan_assasin(server, command)
  kcommand = "ps -ef | grep "#{command}" | grep -v grep | awk '{print $2}' | xargs kill"
  Net::SSH.start(server, 'root', :paranoid => false, :timeout => 30, :auth_methods => "publickey") do |ssh|
    #Timeout::timeout(30) {
      ssh.exec!(kcommand)
    #}
  end # Net::SSH
  response = "Orphans Assasinated: #{kcommand}"
  return response
end

def linecrunch(server, mount)
  # Variable to hold the response
  orphans = String.new
  response = String.new
  command = "mount | grep #{mount}"

  # Block to catch exceptions
  begin

    # Start timeout to save our butts.

    # Ping and SSH checks.
    pingwrap = Timeout::timeout(40) {
    if PingCheck(server) != "Good" then
      raise "Not pingable."
    end
    }
    sshwrap = Timeout::timeout(40) {
    if SShCheck(server) != "Good" then
      raise "Not sshable."
    end
    }

    # If we got here we can do some real work.
    # Open an ssh session
    Net::SSH.start(server, 'root', :paranoid => false, :timeout => 30, :auth_methods => "publickey") do |ssh|
      response = "#{server} -- "
      stdout = ""
      Timeout::timeout(60) {
        ssh.exec!(command) do |channel, stream, data|
          stdout << data if stream == :stdout
        end
      }
       if stdout == "" then
         response = response + "#{mount} is not mounted."
       else
         #response = response + "STDOUT: " + stdout.split[0]
         mntls = "ls -l #{stdout.split[0]}/."
         stderr = ""
         Timeout::timeout(60) {
           ssh.exec!(mntls) do |channel, stream, data|
             stderr << data if stream == :stderr
           end
         }
         if stderr == "" then
           response = response + mount + " on #{stdout.split[0]} working."
         else
           response = response + mount + " on #{stdout.split[0]} failing."
         end
      end 

    end # Close ssh session

    #return response

  rescue TimeoutError => ex
    # Go to the server and kill orphan process left when Timeout
    # expired the session
    #orphan_assasin(server, mntls)
    response = server + " -- WARNING! #{ex.message} accessing #{mount}"

  rescue Exception => ex # Exception catcher
    response = server + " -- BLAMMO! #{ex.class}: #{ex.message}"

  ensure
    return response
  end # Exception block
end #linecrunch

# This object should keep track of all thread this script spawns.
def join_all
  main = Thread.main
  current = Thread.current
  all = Thread.list
  all.each { |t| t.join unless t == current or t == main }
end

def popper
  @workqueue.deq
end

# Iterate over each line of the file and do something
puts "Queueing up processes..."

# An array to hold thread ID's so we know what sub-threads we 
# should wait for.
output = []

# This is the thread that spins up the sub-threads.  Because 
# SizedQueue blocks when the queue is full, we need the sub-threads
# and the reporter object to dequeue them as they finish.
worker = Thread.new {
  @serverlist.each do |line|
    @workqueue << Thread.new(line) { |l| 
      if l =~ /^[a-zA-Z0-9]/ then
        server = l.split(":")[0]
        directory = l.split(":")[1].strip!
        product = linecrunch(server, directory)
        puts product
        @log.puts product
      else # if line does not start with a word.
        #puts "#{l.strip!} -- Line does not meet processing criteria."
      end # if
      output << Thread.new {popper}
    } 
  end  # line processing

  #  This causes the worker thread to wait for all sub-threads to 
  # exit before continuing.
  output.each { |t| t.join }
}

# This waits for the main worker thread to finish before continuing. 
worker.join
join_all

# Just some time arithmetic to measure how long we ran
tstop = Time.now
ttime = tstop - tstart

@log.puts "Script finished in " + ttime.to_s + " seconds."
puts "Script finished in " + ttime.to_s + " seconds."

@log.close

