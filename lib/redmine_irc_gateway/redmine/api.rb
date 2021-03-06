require 'active_resource'

module RedmineIRCGateway
  module Redmine

    class Connection < ActiveResource::Connection

      # override authorization_header method. add Redmine API key to header
      def authorization_header(http_method, uri)
        { 'X-Redmine-API-Key' => API.session.key }
      end

    end

    class API < ActiveResource::Base

      cattr_accessor :session, :connections

      self.connections  = {}

      self.logger       = Logger.new STDOUT
      self.logger.level = Logger::ERROR
      self.proxy        = ENV['http_proxy'] if ENV['http_proxy']
      self.format       = :xml

      begin
        config = RedmineIRCGateway::Config.load
        self.site = config.default['site']
      rescue => e
        self.logger.error e.to_s
        self.logger.error 'Check your $HOME/.rig/config.yml or config/config.yml settings.'
      end

      class << self

        # see [REST issues response with issue count limit and offset](http://www.redmine.org/issues/6140)
        def inherited child
          child.headers['X-Redmine-Nometa'] = '1'
        end

        # override gems/activeresource-3.1.0/lib/active_resource/base.rb
        #
        # An instance of ActiveResource::Connection that is the base \connection to the remote service.
        # The +refresh+ parameter toggles whether or not the \connection is refreshed at every request
        # or not (defaults to <tt>false</tt>).
        def connection(refresh = false)
          if connection = self.connections[session.profile]
            connection
          else
            begin
              site = RedmineIRCGateway::Config.load.get(session.profile)['site'] || self.site
            rescue => e
              logger.info 'Use default site'
              site = self.site
            end

            connection             = Connection.new(site, format)
            connection.proxy       = proxy if proxy
            connection.user        = user if user
            connection.password    = password if password
            connection.auth_type   = auth_type if auth_type
            connection.timeout     = timeout if timeout
            connection.ssl_options = ssl_options if ssl_options

            self.connections[session.profile] = connection
          end
        end

        def site
          self.connections[session.profile].site + '/' rescue super
        end

        def all(params = nil)
          super({ :params => params })
        end

      end

    end
  end
end
