# frozen_string_literal: true

module Features
  module Docker
    class DockerIgnore < Feature
      def initialize(cli, vars)
        super(cli)
        @variables = vars
      end

      def create_file_for(env)
        update_ignore_file(".build/Dockerfile-#{env}.dockerignore", add: entries(env))
      end

      private

      ADDITIONAL = [
        ".dockerignore",
        "config/master.key",
        "Dockerfile",
        {
          "app/assets/builds/*" => "app/assets",
          "config/credentials/*.key" => "config/credentials",
        },
      ].freeze

      # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/app/templates/dockerignore.tt
      FOR_ALL = [
        ".build/",
        ".env*",
        ".git/",
        ".git*",
        ".ruby-version",
        "log/*",
        "tmp/*",
      ].freeze

      FOR_ASSETS = [
        ".pnp.*",
        ".yarn/cache/",
        "node_modules/",
        "public/assets",
      ].freeze

      FOR_STORAGE = [
        "storage/*",
      ].freeze

      WHEN_ENV = {
        ci: [
          ".annotate_solargraph_schema",
          ".overcommit.yml",
          ".vscode/",
          "bin/docker-dev",
        ].freeze,
        development: [
          "bin/docker-entrypoint",
        ].freeze,
        production: [
          ".annotate_solargraph_schema",
          ".overcommit.yml",
          ".rspec",
          ".tools/",
          ".vscode/",
          "bin/docker-dev",
          "spec/",
          "test/",
        ].freeze,
      }.freeze

      private_constant :ADDITIONAL, :FOR_ALL, :FOR_ASSETS, :FOR_STORAGE, :WHEN_ENV

      def entries(env)
        for_all_envs + additional_entries(WHEN_ENV.fetch(env.to_sym, []))
      end

      def for_all_envs
        @for_all_envs ||=
          begin
            entries = prefix_slash(FOR_ALL)
            entries += prefix_slash(FOR_ASSETS) if @variables[:includes_frontend]
            entries += prefix_slash(FOR_STORAGE) if @variables[:includes_active_storage]
            entries += additional_entries(ADDITIONAL)

            entries
          end
      end

      def additional_entries(items)
        entries =
          items.reduce([]) do |result, path|
            result.concat(path.is_a?(Hash) ? multi_file_entries(path) : single_file_entry(path))
          end

        prefix_slash(entries)
      end

      def multi_file_entries(hash)
        hash.each do |file_entry, actual_path|
          single_file_entry(file_entry, actual_path)
        end
      end

      def single_file_entry(file_entry, actual_path = file_entry)
        project_file_exist?(actual_path) ? [file_entry] : []
      end

      def prefix_slash(entries)
        entries.map { |x| "/#{x}" }
      end
    end
  end
end
