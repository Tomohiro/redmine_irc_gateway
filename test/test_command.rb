require_relative 'test_helper'

module RedmineIRCGateway
  module Command
    class CommandTest < ActiveSupport::TestCase

      test 'Check method missing' do
        assert_kind_of Array, Command.me
      end

      test 'Check build description' do
        watch_list = Redmine::Issue.watched
        watch_list.each do |w|
          desc = Command.build_issue_description(w)
          user = w.assigned_to || w.author

          assert_equal user.name.gsub(' ', ''), desc.speaker
        end
      end

      test 'Register command' do
        Command.register do
          command :hello_world do
            'Hello, World!'
          end
        end

        assert_equal 'Hello, World!', Command.hello_world
      end

      test 'Show Issue link' do
        assert_match /http:.+/, Command.link(Redmine::Issue.assigned_me.first.id).first.content
      end

      test 'My issues' do
        assert_kind_of Array, Command.me
      end

      test 'My watched issues' do
        assert_kind_of Array, Command.watch
      end

      test 'My reported issues' do
        assert_kind_of Array, Command.reported
      end

      test 'My time entries' do
        assert_kind_of Array, Command.time
      end

      test 'Help' do
        assert_kind_of Array, Command.help
      end

   end
  end
end
