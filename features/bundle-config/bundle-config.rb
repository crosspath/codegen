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
    end

    private

    DO_NOT_IGNORE = [
      "/.bundle",
    ].freeze

    IGNORE_FILE_ENTRIES = [
      "/.bundle/*",
      "!/.bundle/config.*",
    ].freeze

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
      modified_line = StringUtils.indent(modified_line.split("\n")).join("\n")

      if line_index_with_bundle_call
        file[line_index_with_bundle_call] = modified_line + file[line_index_with_bundle_call]
      else
        file << modified_line
      end

      write_project_file("bin/setup", file.join("\n"))
    end
  end
end
