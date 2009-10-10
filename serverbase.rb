#!/usr/local/bin/ruby
#
# Base functions commonly used when running scripts that touch lots of 
# servers in the environment.
# 29-01-2009 Bill W. Initial design.
# 08-05-2009 Bill W. Added standard multithreading class
#

require "rubygems"
require "net/ssh"
require "ping"
require "open4"
require "thread"
require "ruby-debug"

module BaseServerInfo

  # This class defines how we use threads
  class ThreadPool
    class Worker
      def initialize
        @mutex = Mutex.new
        @thread = Thread.new do
          while true
            sleep 0.001
            block = get_block
            if block
              block.call
              reset_block
            end
          end
        end
      end

      def get_block
        @mutex.synchronize {@block}
      end

      def set_block(block)
        @mutex.synchronize do
          raise RuntimeError, "Thread already busy." if @block
          @block = block
        end
      end

      def reset_block
        @mutex.synchronize {@block = nil}
      end

      def busy?
        @mutex.synchronize {!@block.nil?}
      end
    end # Worker

    attr_accessor :max_size
    attr_reader :workers

    def initialize(max_size = 10)
      @max_size = max_size
      @workers = []
      @mutex = Mutex.new
    end

    def size
      @mutex.synchronize {@workers.size}
    end

    def busy?
      @mutex.synchronize {@workers.any? {|w| w.busy?}}
    end

    def join
      sleep 0.01 while busy?
    end

    def process(&block)
      while true
        @mutex.synchronize do
          worker = find_available_worker
          if worker
            return worker.set_block(block)
          end
        end
        sleep 0.01
      end
    end

    def wait_for_worker
      while true
        worker = find_available_worker
        return worker if worker
        sleep 0.01
      end
    end

    def find_available_worker
      free_worker || create_worker
    end

    def free_worker
      @workers.each {|w| return w unless w.busy?}; nil
    end

    def create_worker
      return nil if @workers.size >= @max_size
      worker = Worker.new
      @workers << worker
      worker
    end
  end #ThreadPool


  def PingCheck(server)
    # Make sure we can ping it first
    pingstatus = "1"
    if Ping.pingecho(server, 10)
      return "Good"
    else
      return "Not Pingable"
    end
  end #pingcheck

  def SShCheck(server)
    begin # rescue block
      # Make sure we can ssh to the server
      # 30 second timeout on the connection.
      answer = String.new
      sshable = "1"
      Net::SSH.start(server, 'root', :paranoid => false, :timeout => 30, :auth_methods => "publickey") do |ssh|
        stdout = ""
        ssh.exec!('hostname') do |channel, stream, data|
          answer = data if stream == :stdout
        end
      end

      if answer.nil? then
        sshable = "Not SSHable"
      else
        sshable = "Good"
      end

    rescue => ex # If an error is encountered, pass it back in the return string

      sshable = "SSH ERROR - #{ex.class}: #{ex.message}" 

    ensure

      return sshable

    end # rescue block
  end #sshcheck

  def OsChecker(server)
    begin # rescue block in case ssh fails
      # Get the ostype and os version from the remote host.
      # This will be used to determine what commands to run.
      # Executes uname -r and uname -s on the remote host.

      oscheck = Hash.new
      osversion = String.new
      ostype = String.new
  
      # Now using Net::SSH to do the heavy lifting
      Net::SSH.start(server, 'root', :paranoid => false, :timeout => 30, :auth_methods => "publickey") do |ssh|
        stdout = ""
        ssh.exec!('/usr/bin/uname -r') do |channel, stream, data|
          osversion = data if stream == :stdout
        end
        ssh.exec!('/usr/bin/uname -s') do |channel, stream, data|
          ostype = data if stream == :stdout
        end
      end

      oscheck[:osversion] = osversion.strip
      oscheck[:ostype] = ostype.strip
      oscheck[:errmsg] = ""

    rescue => ex  # If an error is encountered, pass it back in the return 

      if osversion.nil? then
        oscheck[:osversion] = osversion.strip
      else
        oscheck[:osversion] = "SSH ERROR"
      end
      if ostype.nil? then
        oscheck[:ostype] = ostype.strip
      else
        oscheck[:ostype] = "SSH ERROR"
      end

      oscheck[:errmsg] = "SSH ERROR - #{ex.class}: #{ex.message}"

    ensure # Always do this

      return oscheck

    end # rescue block
  end # oscheck
 
  def ldapcheck(user)
    # assumes SunOS
    command = "getent passwd #{user}"
    status = Open4::popen4("ksh") do |pid, stdin, stdout, stderr|
      stdin.puts command
      stdin.close
    end

    return status.exitstatus

  end # ldapcheck

end # Module BaseServerInfo
