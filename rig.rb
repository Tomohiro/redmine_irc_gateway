#!/usr/bin/env ruby
# vim:encoding=UTF-8:

$LOAD_PATH << (RUBY_VERSION > '1.9' ? './lib' : 'lib')

$KCODE = 'u' unless defined? ::Encoding

require 'redmine_irc_gateway'

if __FILE__ == $0
  require "optparse"

  opts = {
    :port  => 16700,
    :host  => "localhost",
    :log   => nil,
    :debug => false,
    :foreground => false,
  }

  OptionParser.new do |parser|
    parser.instance_eval do
      self.banner  = <<-EOB.gsub(/^\t+/, "")
        Usage: #{$0} [opts]

      EOB
separator ""

      separator "Options:"
      on("-p", "--port [PORT=#{opts[:port]}]", "port number to listen") do |port|
        opts[:port] = port
      end

      on("-h", "--host [HOST=#{opts[:host]}]", "host name or IP address to listen") do |host|
        opts[:host] = host
      end

      on("-l", "--log LOG", "log file") do |log|
        opts[:log] = log
      end

      on("--debug", "Enable debug mode") do |debug|
        opts[:log]   = $stdout
        opts[:debug] = true
      end

      on("-f", "--foreground", "run foreground") do |foreground|
        opts[:log]        = $stdout
        opts[:foreground] = true
      end

      parse!(ARGV)
    end
  end

  opts[:logger] = Logger.new(opts[:log], "daily")
  opts[:logger].level = opts[:debug] ? Logger::DEBUG : Logger::INFO

  def daemonize(foreground=false)
    trap("SIGINT")  { exit! 0 }
    trap("SIGTERM") { exit! 0 }
    trap("SIGHUP")  { exit! 0 }
    return yield if $DEBUG || foreground
    Process.fork do
      Process.setsid
      Dir.chdir "/"
      File.open("/dev/null") {|f|
        STDIN.reopen  f
        STDOUT.reopen f
        STDERR.reopen f
      }
      yield
    end
    exit! 0
  end

  daemonize(opts[:debug] || opts[:foreground]) do
    Net::IRC::Server.new(opts[:host], opts[:port], RedmineIrcGateway::Server, opts).start
  end
end
