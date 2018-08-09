#!/usr/local/bin/ruby
#
# This script is written in Ruby
# It will go through the list of protocols and servers, check to see
# if the protocol is active in inetd, and turn it off if it is.
# 09-01-22 - Bill W. Initial program design
# 21-04-09 - Bill W. Changed input file to be a simple list of servers.

# Pulling in the gems we need to do this
require 'rubygems'
require 'net/ssh'
require 'open4'

# Define some variable we're going to need.
@inputdir = "/input/dir"
@outputdir = "/output/dir"
@inputfile = "input.csv"
@outputfile = "oiutput.txt"

# Define the keywords we're going to look for, by OS
sol10key = ["wall"]
solbasekey = ["wall"]
hpbasekey = ["wall"]


def pingcheck(server)
  # Make sure we can ping it first
  command = "ping"
  pid, stdin, stdout, stderr = Open4::popen4 "sh"

  stdin.puts command + " " + server + "  2>/dev/null"
  stdin.close

  ignored, status = Process::waitpid2 pid

  pingstatus = status.exitstatus

  if pingstatus == 0 then
    return "Good"
  else
    return "Not Pingable"
  end
end #pingcheck

def sshcheck(server)
  # Make sure we can ssh to the server
  # 30 second timeout on the connection.
  answer = String.new
  sshable = "1"
  Net::SSH.start(server, 'root', :paranoid => false, :timeout => 30) do |ssh|
    stdout = ""
    ssh.exec!('hostname') do |channel, stream, data|
      answer = data if stream == :stdout
    end
  end

  if answer.nil? then
    sshable = "1"
  else
    sshable = "Good"
  end

  return sshable
end #sshcheck

def oscheck( server )

  # Get the ostype and os version from the remote host.
  # This will be used to determine what commands to run.
  # Executes uname -r and uname -s on the remote host.

  oscheck = Hash.new
  osversion = String.new
  ostype = String.new

  # Now using Net::SSH to do the heavy lifting
  Net::SSH.start(server, 'root', :paranoid => false, :timeout => 30) do |ssh|
    stdout = ""
    ssh.exec!('uname -r') do |channel, stream, data|
      osversion = data if stream == :stdout
    end
    ssh.exec!('uname -s') do |channel, stream, data|
      ostype = data if stream == :stdout
    end
  end

  oscheck[:osversion] = osversion.strip
  oscheck[:ostype] = ostype.strip
  # Return the hash
  return oscheck
end # oscheck

########  MAIN #########

# Setup the logfile
Dir.chdir(@outputdir)
if File.exists?(@outputfile) then
  # Rename
  suffix = Time.now
  File.rename(@outputfile, "#{@outputfile}.#{suffix.strftime("%X")}")
end # Check for existing output file

# Timer for the curious
starttime = Time.now

# Open the output file
File.open(@outputfile, "w") do |log|
  log.puts "Starting inetdoff run at " + Time.now.strftime("%Y-%m-%d %H:%M:%S")
  puts "Starting inetdoff run at " + Time.now.strftime("%Y-%m-%d %H:%M:%S")
  log.puts "Using input file " + @inputfile + ", in directory " + @inputdir
  puts "Using input file " + @inputfile + ", in directory " + @inputdir

  # Open the input file 
  lines = File.open(@inputfile, "r")
	
  # Block to iterate over each line
  lines.each  { |line|
    # Ignore lines beginning with "#"
    if line =~ /^\#/ then
      log.puts "Skipping line: " + line
      puts "Skipping line: " + line
    else
      server = line.strip
      stime = Time.now
      log.puts "Working on server " + server
      puts "Working on server " + server

      # Start a block to capture exceptions
      begin
        if pingcheck(server) != "Good" then
          raise "Not pingable."
        end

	if sshcheck(server) != "Good" then
          raise "Not sshable."
	end
					
	# Determine the OS we're working on
	osinfo = oscheck(server)
	log.puts "\t" + "OS is: " + osinfo[:ostype] + "\t" + "OS version is: " + osinfo[:osversion] 
	puts "\t" + "OS is: " + osinfo[:ostype] + "\t" + "OS version is: " + osinfo[:osversion] 
  # Determine what we're going to do
	case
    when osinfo[:ostype] == "SunOS" && osinfo[:osversion] == "5.10"
	    @daemons = sol10key
    when osinfo[:ostype] == "SunOS" && osinfo[:osversion] != "5.10"
      @restart = "/usr/bin/pkill -HUP inetd"
      @daemons = solbasekey
      @inetconf = "/etc/inet/inetd.conf"
    when osinfo[:ostype] == "HP-UX"
      @restart = "/usr/sbin/inetd -c"
      @daemons = hpbasekey
      @inetconf = "/etc/inetd.conf"
  end #case

	# Execute on each server
  Net::SSH.start(server, 'root', :paranoid => false, :timeout => 30) do |ssh|
    #Backup the inetd.conf file
    log.puts "\t" + "Backing up existing inetd.conf."
    puts "\t" + "Backing up existing inetd.conf."
    if osinfo[:ostype] == "SunOS" then
      ssh.exec!('cp /etc/inet/inetd.conf /etc/inet/inetd.conf.bkup')
    else
      ssh.exec!('cp /etc/inetd.conf /etc/inetd.conf.bkup')
    end # Backup

    # Switch variable if we need to restart inetd or not.
    inetrestart = "no"

    @daemons.each { |daemon|
    if osinfo[:ostype] == "SunOS" && osinfo[:osversion] == "5.10" then
      command = "svcs -a  | grep " + daemon 
      stdout = String.new
      ssh.exec!(command) do |channel, stream, data|
      stdout << data if stream == :stdout
    end
    stdout.split("\n").each { |output|
      if output.strip.split[0] == "disabled" then
        log.puts "\t" + output.strip.split[2] + " is already disabled."
        puts "\t" + output.strip.split[2] + " is already disabled."
      else
        log.puts "\t" + "Turning off " + output.strip.split[2] + "."
        puts "\t" + "Turning off " + output.strip.split[2] + "."
        command = "svcadm disable " + output.strip.split[2]
		    ssh.exec!(command)
      end
    }

    else # What to do for the other OS 
      command = "grep " + daemon + " " + @inetconf
      stdout = String.new
      ssh.exec!(command) do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      stdout.split("\n").each { |output|
        if output.split[0] =~ /^#{daemon}/
          log.puts "\t" + "Turning off " + daemon
          puts "\t" + "Turning off " + daemon
          command = "cat /etc/inetd.conf | sed 's/^" + daemon + "*/#&/' > /etc/inetd.conf.changed" 
          ssh.exec!(command)
          command = "cp /etc/inetd.conf.changed " + @inetconf
          ssh.exec!(command)
          inetrestart = "yes"
        elsif output.split[0] =~ /^\##{daemon}/
          log.puts "\t" + daemon + " line already commented."
          puts "\t" + daemon + " line already commented."
        end
      }
    end # What to do for each OS

  }

	# And finally, restart the inetd process if changes happend.
	# This is not applicable to Sol10 services handled by SMF.
	if inetrestart == "yes" then
    log.puts "\t" + "inetd.conf changed, restarting daemon."
    puts "\t" + "inetd.conf changed, restarting daemon."
    tries = 0
    begin
      ssh.exec!(@restart)
    rescue Net::SSH::ChannelOpenFailed
      command = "ssh -n " + server + " " +  @restart + " 2>/dev/null"
      pid, stdin, stdout, stderr = Open4::popen4 "sh"
      stdin.puts command 
      stdin.close
      ignored, status = Process::waitpid2 pid

    end
	end # inetd restart

end

rescue Timeout::Error

  log.puts "\t" + "Request Timed Out."
  puts "\t" + "Request Timed Out."

rescue => ex # If an error is encountered, log it to the log file

  log.puts "\t" + "ERROR - #{ex.class}: #{ex.message}"
  puts "\t" + "ERROR - #{ex.class}: #{ex.message}"

ensure # rescue block - always do this.

  etime = Time.now
  ttime = etime - stime
  log.puts "Time spent on server " + server + ": " + ttime.to_s
  puts "Time spent on server " + server + ": " + ttime.to_s

end # rescue block

end # Ignore "#"

} #End block acting on input file

log.puts "Ending inetdoff run at " + Time.now.strftime("%Y-%m-%d %H:%M:%S")
puts "Ending inetdoff run at " + Time.now.strftime("%Y-%m-%d %H:%M:%S")
endtime = Time.now
totaltime = endtime - starttime
log.puts "It took " + totaltime.to_s + " seconds to run this script."
puts "It took " + totaltime.to_s + " seconds to run this script."

end # Closes output file

