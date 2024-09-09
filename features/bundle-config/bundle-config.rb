# frozen_string_literal: true

module Features
  # https://bundler.io/v2.4/man/bundle-config.1.html
  class BundleConfig < Feature
    register_as "bundle-config"

    def call
      puts "Copy files to .bundle directory..."
      copy_configs

      puts "Updating .gitignore file..."
      update_ignore_file(".gitignore", add: IGNORE_FILE_ENTRIES, delete: DO_NOT_IGNORE)

      puts "Updating .dockerignore file..."
      update_ignore_file(".dockerignore", add: IGNORE_FILE_ENTRIES, delete: DO_NOT_IGNORE)

      puts "Updating bin/setup file..."
      update_bin_setup

      reset_owner_of_gemfile_lock
    end

    private

    DO_NOT_IGNORE = [
      "/.bundle",
    ].freeze

    IGNORE_FILE_ENTRIES = [
      "/.bundle/*",
      "!/.bundle/config.*",
    ].freeze

    GEMFILE_LOCK = "Gemfile.lock"

    def copy_configs
      create_project_dir(".bundle")

      copy_files_to_project("config.ci", ".bundle")
      copy_files_to_project("config.production", ".bundle")

      erb("config.development", ".bundle/config", system_ruby: Env.system_ruby?)
      erb("config.development", ".bundle/config.development", system_ruby: false)
    end

    def update_bin_setup
      file = read_project_file("bin/setup").split("\n")
      line_index_with_bundle_call = file.find_index { |line| line.include?("bundle") }

      modified_line = <<~RUBY
        if !File.exist?(".bundle/config") && File.exist?(".bundle/config.development")
          `cp .bundle/config.development .bundle/config`
        end
      RUBY

      # Add 2 spaces.
      modified_line = StringUtils.indent(modified_line.split("\n")).join("\n") + "\n"

      if line_index_with_bundle_call
        file[line_index_with_bundle_call] = modified_line + file[line_index_with_bundle_call]
      else
        file << modified_line
      end

      write_project_file("bin/setup", file.join("\n"))
    end

    def reset_owner_of_gemfile_lock
      if project_file_exist?(GEMFILE_LOCK)
        return if current_user_owns_gemfile_lock?

        puts "Reset owner of #{GEMFILE_LOCK} to current user..."
        change_owner_of_gemfile_lock
      else
        write_project_file(GEMFILE_LOCK, "")
      end
    end

    def current_user_owns_gemfile_lock?
      File.owned?(File.join(cli.app_path, GEMFILE_LOCK))
    end

    def change_owner_of_gemfile_lock
      user = ENV["USER"]
      run_command_in_project_dir("sudo chown #{user}:#{user} #{GEMFILE_LOCK}")
    end
  end
end
