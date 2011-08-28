module RedmineIRCGateway
  module Redmine
    extend self

    ##
    # Return Redmine all issues, and save to database.
    #
    # db[redmine issue id] = redmine issue datetime at update
    #
    #
    def all
      db = SDBM.open DB_PATH
      issues = []
      most_old_updated_on = db.values.first || Issue.all.first.updated_on

      Issue.all.reverse.each do |issue|
        key = issue.id
        if db.include? key
          next if db[key] == issue.updated_on

          db[key] = issue.updated_on
          issues << build_issue_description(issue, :update)
        else
          next if most_old_updated_on > issue.updated_on

          db[key] = issue.updated_on
          issues << build_issue_description(issue)
        end
      end
      issues
    rescue => e
      puts e
    ensure
      db.close
    end

    def list
      Issue.assigned_me.reverse.collect { |i| build_issue_description(i) }
    end

    def watch
      Issue.watched.reverse.collect { |i| build_issue_description(i) }
    end

    def online_users project_id
      issues = Project.find(project_id).issues
      if issues
        authors = issues.collect { |i| i.author.name.gsub(' ', '') }
        members = issues.collect { |i| i.assigned_to.name.gsub(' ', '') if defined? i.assigned_to }
        (authors + members).uniq
      end
    end

    def build_issue_description issue, updated = false
      OpenStruct.new({
        :author       => issue.author.name.gsub(' ', ''),
        :project_id   => issue.project.id,
        :project_name => issue.project.name,
        :content      => [
                          updated ? "4Up!" : nil,
                          issue.tracker.name,
                          "3#{issue.status.name}",
                          "6#{issue.priority.name}",
                          "#{issue.subject}",
                          "14(#{issue.done_ratio}%)",
                          "14#{issue.uri}"
                         ].join(' ')
      })
    end

  end
end
