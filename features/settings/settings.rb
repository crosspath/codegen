# frozen_string_literal: true

module Features
  class Settings < Feature
    register_as "settings"

    def call
      puts "Add gem for settings..."
      add_gem("settings", git: "https://github.com/crosspath/ruby-settings")

      puts "Copy example files..."
      copy_example_files

      puts "Inject into #{CONFIG_APPLICATION}..."
      inject_into_config

      puts "Updating .gitignore file..."
      update_ignore_file(".gitignore", add: IGNORE_FILE_ENTRIES)

      puts "Updating .dockerignore file..."
      update_ignore_file(".dockerignore", add: IGNORE_FILE_ENTRIES)
    end

    private

    CONFIG_APPLICATION = "config/application.rb"
    IGNORE_FILE_ENTRIES = ["/config/settings/*.local.*"].freeze

    private_constant :CONFIG_APPLICATION, :IGNORE_FILE_ENTRIES

    def copy_example_files
      copy_files_to_project("configs", "bin/configs")

      create_project_dir("config/settings")
      copy_files_to_project("initializer.rb", "config/settings.rb")
      copy_files_to_project("default.yml", "config/settings/default.yml")
    end

    def inject_into_config
      config = read_project_file(CONFIG_APPLICATION)
      config.sub!(/^module /, "require_relative \"settings\"\n\nmodule ")
      write_project_file(CONFIG_APPLICATION, config)
    end
  end
end
