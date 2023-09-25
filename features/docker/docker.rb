# frozen_string_literal: true

require "json"

module Features
  # @see Dockerfile syntax: https://docs.docker.com/engine/reference/builder/
  # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/app_base.rb
  class Docker < Feature
    register_as "docker"

    def call
      gemfile_lock = read_project_file("Gemfile.lock").split("\n")
      package_json =
        project_file_exist?("package.json") ? JSON.parse(read_project_file("package.json")) : nil

      locals = {
        ruby_version: read_project_file(".ruby-version").strip,
        bundler_version: gemfile_lock.match(/\nBUNDLED WITH\n\s*(\S+)/)[1],
        includes_frontend: !package_json.nil?,
        includes_bun: !package_json.nil? && project_file_exist?("bun.config.js"),
        yarn_version: !package_json.nil? && package_json["packageManager"].match(/^yarn@(.+)$/)&.[](1)
        add_chromium: cli.ask.yes?(label: "Add packages for Chromium", default: ->(_, _) { "n" }),
        database_packages: database_packages,
        includes_active_storage: active_storage?,
        includes_sidekiq: !gemfile_lock.grep(/^\s*sidekiq\s/).empty?,
      }

      if project_file_exist?("config/database.yml")
        dbms = read_project_file("config/database.yml").match(/\n  adapter:([^\n#]+)/)[1].strip
        locals[:database_packages] = DMBS_PACKAGES[dbms] if DMBS_PACKAGES[dbms]
      end

      erb("Dockerfile", "Dockerfile", **locals)
    end

    private

    DMBS_PACKAGES = {
      "mysql" => "default-libmysqlclient-dev default-mysql-client",
      "postgresql" => "libpq-dev postgresql-client",
      "sqlite3" => "libsqlite3-0",
      # "oracle",
      # "sqlserver",
      # "jdbcmysql",
      # "jdbcsqlite3",
      # "jdbcpostgresql",
      # "jdbc"
    }.freeze

    def database_packages
      return unless project_file_exist?("config/database.yml")

      dbms = read_project_file("config/database.yml").match(/\n  adapter:([^\n#]+)/)&.[](1)&.strip
      DMBS_PACKAGES[dbms]
    end

    def active_storage?
      config_application = read_project_file("config/application.rb").split("\n")
      config_application.any? { |line| line.start_with?('require "rails/all"', 'require "active_storage/engine"') }
    end
  end
end
