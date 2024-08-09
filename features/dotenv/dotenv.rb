# frozen_string_literal: true

module Features
  class Dotenv < Feature
    register_as "dotenv"

    def call
      puts "Add gem dotenv..."
      add_gem("dotenv")

      puts "Copy example files..."
      copy_files_to_project("configs", "bin/configs")

      ENV_FILES.each do |env_file|
        write_project_file(env_file, ENV_FILE_TEXT) unless project_file_exist?(env_file)
      end

      puts "Updating .gitignore file..."
      update_ignore_file(".gitignore", delete: DO_NOT_IGNORE)

      puts "Updating .dockerignore file..."
      update_ignore_file(".dockerignore", delete: DO_NOT_IGNORE)
    end

    private

    DATABASE_URL = "postgres://myuser:mypass@localhost/somedatabase"

    ENV_FILE_TEXT = "DATABASE_URL=#{DATABASE_URL}\n"

    ENV_FILES = %w[.env.template .env.test].freeze

    DO_NOT_IGNORE = [
      "/.env*",
      "!/.env*.erb",
    ].freeze
  end
end
