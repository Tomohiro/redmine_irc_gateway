module RedmineIRCGateway
  class Channel < Hash

    attr_reader :name, :users, :project_id, :topic, :channels

    class << self

      # Return main channel instance
      def timeline
        self.new({ :name => :Redmine, :project_id => 0 })
      end

      # Return all channel instances
      def all_by_me user
        self.new({ :me => user }).list
      end

    end

    def initialize(params = nil)
      if params
        @me         = params[:me]
        @name       = "##{params[:name]}"
        @users      = params[:users] || []
        @project_id = params[:project_id]
        @topic      = params[:topic] || ''
      end
    end

    # Return all channel names
    def names
      config = Config.load.get(@me.profile)
      config['channels'] rescue []
    end

    # Return all channel instances
    def list
      names.each { |name, id| add(get(name, id.to_s)) } rescue {}
      self
    end

    # Add channel instance to stack
    def add channel
      self[channel.project_id] = channel
    end

    # Find channel instance at stack
    def find project_id
      self[project_id]
    end

    # Return find or create channel instance
    def get(channel_name, project_id)
      channel = find project_id
      unless channel
        @me.connect_redmine
        project = Redmine::Project.find project_id
        channel = Channel.new({
          :me         => @me,
          :name       => channel_name,
          :project_id => project_id,
          :users      => project.members,
          :topic      => project.description
        })
      end
      channel
    end

  end
end
