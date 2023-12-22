# frozen_string_literal: true

module Features
  class Misc < Feature
    register_as "misc"

    def call
      puts "Update bin/setup file..."
      update_bin_setup

      if project_file_exist?(LOCALES_EN)
        puts "Check #{LOCALES_EN} file..."
        remove_locales_en
      end

      puts "Check app/helpers..."
      remove_app_helpers

      puts "Check lib/assets..."
      remove_lib_assets

      puts "Check test/helpers..."
      remove_test_helpers

      puts "Check vendor..."
      remove_vendor

      puts "Updating .gitignore file..."
      update_ignore_file(".gitignore", add: IGNORE_FILE_ENTRIES)

      puts "Updating .dockerignore file..."
      update_ignore_file(".dockerignore", add: IGNORE_FILE_ENTRIES)
    end

    private

    BIN_SETUP = "bin/setup"

    BIN_SETUP_BEFORE = <<~RUBY
      puts "\n== Preparing database =="
      system! "bin/rails db:prepare"

      puts "\n== Removing old logs and tempfiles =="
      system! "bin/rails log:clear tmp:clear"

      puts "\n== Restarting application server =="
      system! "bin/rails restart"
    RUBY

    BIN_SETUP_AFTER = <<~RUBY
      puts "\n== Preparing database =="
      system! "bin/rails db:prepare log:clear tmp:clear"
    RUBY

    LOCALES_EN = "config/locales/en.yml"

    APP_HELPER = "application_helper.rb"
    APP_HELPER_TEXT = <<~RUBY
      module ApplicationHelper
      end
    RUBY

    IGNORE_FILE_ENTRIES = [
      "*.local",
      ".DS_Store",
      ".directory",
      "Thumbs.db",
      "[Dd]esktop.ini",
      "~$*",
    ].freeze

    def update_bin_setup
      bin_setup = read_project_file(BIN_SETUP)
      text_before = indent(BIN_SETUP_BEFORE.lines).join.strip
      text_after = indent(BIN_SETUP_AFTER.lines).join.strip

      bin_setup.sub!(text_before, text_after)
      write_project_file(BIN_SETUP, bin_setup)
    end

    def remove_locales_en
      require "psych"

      locales_en = Psych.safe_load(read_project_file(LOCALES_EN))
      remove_project_file(LOCALES_EN) if locales_en == {"en" => {"hello" => "Hello world"}}
    end

    def remove_app_helpers
      remove_project_dir(File.join("app/helpers", APP_HELPER)) if may_delete_app_helpers?
    end

    def may_delete_app_helpers?
      files = project_files("app/helpers", "**/*")
      return true if files.empty?
      return false if files != [APP_HELPER]

      read_project_file(File.join("app/helpers", APP_HELPER)).strip == APP_HELPER_TEXT.strip
    end

    def remove_lib_assets
      remove_project_dir("lib/assets") if dir_exists?("lib/assets") && dir_empty?("lib/assets")
    end

    def remove_test_helpers
      remove_project_dir("test/helpers") if dir_exists?("test/helpers") && dir_empty?("test/helpers")
    end

    def remove_vendor
      remove_project_dir("vendor") if dir_exists?("vendor") && dir_empty?("vendor")
    end

    def dir_exists?(dir_name)
      Dir.exist?(File.join(cli.app_path, dir_name))
    end

    def dir_empty?(dir_name)
      project_files(dir_name, "**/*").grep_v(/^\.keep$|\/\.keep$/).empty?
    end
  end
end
