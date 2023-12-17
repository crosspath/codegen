# frozen_string_literal: true

module Features
  class Settings < Feature
    register_as "settings"

    def call
      puts "Copy app/lib/settings.rb file..."
      copy_lib_file

      puts "Copy example files..."
      copy_example_files
    end

    private

    def copy_lib_file
      run_command_in_project_dir("mkdir -p app/lib")
      copy_files_to_project("settings.rb", "app/lib/settings.rb")
    end

    def copy_example_files
      run_command_in_project_dir("mkdir -p config/initializers")
      copy_files_to_project("initializer.rb", "config/initializers/settings.rb")
      copy_files_to_project("settings.yml", "config/settings.yml")
    end
  end
end
