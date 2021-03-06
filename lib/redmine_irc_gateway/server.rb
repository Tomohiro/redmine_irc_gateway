require 'logger'
require 'slop'

module RedmineIRCGateway
  class Server
    attr_accessor :opts

    class << self
      def run!
        self.new.start
      end
    end

    def initialize
      @opts = Slop.parse :help => true do
        banner "Usage: #{$0} [options]"
        on :p, :port,    'Port number to listen',             true,  :as => :integer, :default => 16700
        on :s, :server,  'Host name or IP address to listen', true,  :as => :string,  :default => nil
        on :l, :log,     'Log file',                          true,  :as => :string,  :default => nil
        on :d, :debug,   'Enable debug mode',                 false, :as => :boolean, :default => false
        on :v, :version, 'Print the version' do
          puts VERSION
          exit
        end
      end.to_hash

      exit if @opts[:help]

      @opts.each do |key, val|
        puts "#{key}: #{val}" if !val.nil?
      end

      @opts[:logger] = Logger.new STDOUT
      @opts[:logger].level = @opts[:debug] ? Logger::DEBUG : Logger::INFO
    end

    def start
      Net::IRC::Server.new(@opts[:host], @opts[:port], RedmineIRCGateway::Session, @opts).start
    end

  end
end
