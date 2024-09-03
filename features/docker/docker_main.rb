# frozen_string_literal: true

require "json"

module Features
  module Docker
    # @see Dockerfile syntax: https://docs.docker.com/engine/reference/builder/
    # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/app_base.rb
    class DockerMain < Feature
      register_as "docker"

      def call
        configuration = Configuration.new(cli)
        configuration.call

        puts "Creating Dockerfiles & .dockerignore files..."
        create_dockerfiles_and_dockerignore_files(configuration)

        puts "Creating file for Docker Compose..."
        create_compose_file(configuration)

        puts "Add `tzinfo-data` gem..."
        add_gem("tzinfo-data")
      end

      private

      # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/app/templates/dockerignore.tt
      IGNORE_FILE_ENTRIES = [
        "/.annotate_solargraph_schema", # TODO: check file existance.
        "/.build/",
        "/.env*",
        "/.git/",
        "/.git*",
        "/.overcommit.yml", # TODO: check file existance.
        "/.ruby-version",
        "/app/assets/builds/*",
        "/config/master.key",
        "/config/credentials/*.key",
        "/log/*",
        "/tmp/*",
      ].freeze

      IGNORE_FILE_ENTRIES_FOR_ASSETS = [
        "/.pnp.*",
        "/.yarn/cache/",
        "/node_modules/",
        "/public/assets",
      ].freeze

      IGNORE_FILE_ENTRIES_FOR_STORAGE = [
        "/storage/*",
      ].freeze

      private_constant :IGNORE_FILE_ENTRIES, :IGNORE_FILE_ENTRIES_FOR_ASSETS, :IGNORE_FILE_ENTRIES_FOR_STORAGE

      # DOCKERFILE_ENV = %w[ci development production].freeze
      DOCKERFILE_ENV = %w[production].freeze

      def create_dockerfiles_and_dockerignore_files(configuration)
        locals = configuration.dockerfile_variables
        entries = dockerignore_entries(locals)

        create_project_dir(".build")

        DOCKERFILE_ENV.each do |env|
          file_name = "Dockerfile-#{env}"
          erb(file_name, ".build/#{file_name}", **locals)
          update_ignore_file(".build/#{file_name}.dockerignore", add: entries)
        end
      end

      def create_compose_file(configuration)
        erb("compose.yaml", ".build/compose.yaml", **configuration.compose_variables)
      end

      def dockerignore_entries(variables)
        entries = IGNORE_FILE_ENTRIES
        entries += IGNORE_FILE_ENTRIES_FOR_ASSETS if variables[:includes_frontend]
        entries += IGNORE_FILE_ENTRIES_FOR_STORAGE if variables[:includes_active_storage]

        entries
      end
    end
  end
end
