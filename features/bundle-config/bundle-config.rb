# frozen_string_literal: true

module Features
  # https://bundler.io/v2.4/man/bundle-config.1.html
  class BundleConfig < Feature
    register_as "bundle-config"

    def call
      puts "Copy files to .bundle directory..."
      copy_files_to_project("", ".bundle")
      copy_files_to_project("config.development", ".bundle/config")

      puts "Updating .gitignore file..."
      update_ignore_file(".gitignore", add: IGNORE_FILE_ENTRIES)

      puts "Updating .dockerignore file..."
      update_ignore_file(".dockerignore", add: IGNORE_FILE_ENTRIES)

      puts "Updating bin/setup file..."
      update_bin_setup
    end

    private

    IGNORE_FILE_ENTRIES = [
      "/.bundle/*",
      "!/.bundle/config.development",
      "!/.bundle/config.production",
    ].freeze

    def update_bin_setup
      file = read_project_file("bin/setup").split("\n")
      line_index_with_bundle_call = file.find_index { |line| line.include?("bundle") }

      modified_line = <<~RUBY
        if !File.exist?(".bundle/config") && File.exist?(".bundle/config.development")
          `cp .bundle/config.development .bundle/config`
        end
      RUBY

      if line_index_with_bundle_call
        file[line_index_with_bundle_call] = modified_line + file[line_index_with_bundle_call]
      else
        file << modified_line
      end

      write_project_file("bin/setup", file.join("\n"))
    end
  end
end
