# frozen_string_literal: true

require_relative "docker_ignore"

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

        puts "Updating #{ENTRYPOINT}..."
        update_entrypoint
      end

      private

      # DOCKERFILE_ENV = %w[ci development production].freeze
      DOCKERFILE_ENV = %w[production].freeze

      ENTRYPOINT = "bin/docker-entrypoint"

      private_constant :DOCKERFILE_ENV, :ENTRYPOINT

      def create_dockerfiles_and_dockerignore_files(configuration)
        locals = configuration.dockerfile_variables
        ignore = DockerIgnore.new(cli, locals)

        create_project_dir(".build")

        DOCKERFILE_ENV.each do |env|
          erb("Dockerfile-#{env}", ".build/Dockerfile-#{env}", **locals)
          ignore.create_file_for(env)
        end
      end

      def create_compose_file(configuration)
        erb("compose.yaml", ".build/compose.yaml", **configuration.compose_variables)
      end

      def update_entrypoint
        file = read_project_file(ENTRYPOINT)
        file.sub!("#!/bin/bash -e", "#!/bin/sh -e")
        write_project_file(ENTRYPOINT, file)
      end
    end
  end
end
