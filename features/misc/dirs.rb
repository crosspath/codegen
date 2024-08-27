# frozen_string_literal: true

module Features
  module Misc
    class Dirs < Feature
      def call
        remove_app_helpers
        remove_maybe_empty_dirs
        remove_app_channels if !project_file_exist?(APP_CHANNELS) || !use_web_sockets?
      end

      private

      APP_CHANNELS = "app/channels"
      APP_HELPERS = "app/helpers"

      APPLICATION_HELPER = "application_helper.rb"
      APPLICATION_HELPER_TEXT = <<~RUBY
        module ApplicationHelper
        end
      RUBY

      MAYBE_EMPTY_DIRS = %w[lib/assets test/helpers vendor].freeze

      DOT_KEEP = %r{^\.keep$|/\.keep$}

      private_constant :APP_HELPERS, :APPLICATION_HELPER, :APPLICATION_HELPER_TEXT
      private_constant :MAYBE_EMPTY_DIRS, :DOT_KEEP

      def remove_app_helpers
        puts "Check app/helpers..."
        remove_project_dir(APP_HELPERS) if may_delete_app_helpers?
      end

      def may_delete_app_helpers?
        files = project_files(APP_HELPERS, "**/*")
        return true if files.empty?
        return false if files != [APPLICATION_HELPER]

        file_name = File.join(APP_HELPERS, APPLICATION_HELPER)

        read_project_file(file_name).strip == APPLICATION_HELPER_TEXT.strip
      end

      def remove_maybe_empty_dirs
        MAYBE_EMPTY_DIRS.each do |dir|
          puts "Check #{dir}..."
          remove_project_dir(dir) if dir_exists?(dir) && dir_empty?(dir)
        end
      end

      def use_web_sockets?
        cli.ask.question(
          type: :boolean,
          label: "Keep WebSockets support",
          default: ->(_, _) { "n" }
        )
      end

      def remove_app_channels
        puts "Removing #{APP_CHANNELS} directory..."
        remove_project_dir(APP_CHANNELS)
      end

      def dir_exists?(dir_name)
        Dir.exist?(File.join(cli.app_path, dir_name))
      end

      def dir_empty?(dir_name)
        project_files(dir_name, "**/*").grep_v(DOT_KEEP).empty?
      end
    end
  end
end
