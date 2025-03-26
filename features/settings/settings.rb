# frozen_string_literal: true

module Features
  class Settings < Feature
    register_as "settings"

    def call
      puts "Add gem for settings..."
      add_gem("settings", git: "https://github.com/crosspath/ruby-settings")

      puts "Copy example files..."
      copy_example_files

      puts "Update application configs..."
      inject_into_config

      puts "Updating .gitignore file..."
      update_ignore_file(".gitignore", add: IGNORE_FILE_ENTRIES)

      puts "Updating .dockerignore file..."
      update_ignore_file(".dockerignore", add: IGNORE_FILE_ENTRIES)
    end

    private

    IGNORE_FILE_ENTRIES = ["/config/settings/*.local.*"].freeze

    private_constant :IGNORE_FILE_ENTRIES

    def copy_example_files
      copy_files_to_project("configs", "bin/configs")

      create_project_dir("config/settings")
      copy_files_to_project("initializer.rb", "config/settings.rb")
      copy_files_to_project("default.yml", "config/settings/default.yml")
    end

    def inject_into_config
      ConfigApplication.new(cli.app_path).append_to_requires(['require_relative "settings"'])
    end
  end
end
