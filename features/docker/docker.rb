# frozen_string_literal: true

require "json"

module Features
  # @see Dockerfile syntax: https://docs.docker.com/engine/reference/builder/
  # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/app_base.rb
  class Docker < Feature
    register_as "docker"

    def call
      @gemfile_lock = read_project_file("Gemfile.lock").split("\n")
      package_json =
        project_file_exist?("package.json") ? JSON.parse(read_project_file("package.json")) : nil

      locals = {
        ruby_version: read_project_file(".ruby-version").strip,
        bundler_version: bundler_version,
        includes_frontend: !package_json.nil?,
        includes_bun: !package_json.nil? && project_file_exist?("bun.config.js"),
        includes_yarn: !package_json.nil? && package_json["packageManager"] =~ /^yarn@$/,
        add_chromium: cli.ask.yes?(label: "Add packages for Chromium", default: ->(_, _) { "n" }),
        database_packages: database_packages,
        includes_active_storage: active_storage?,
        includes_sidekiq: !@gemfile_lock.grep(/^\s*sidekiq\s/).empty?,
        has_node_modules: Dir.exist?(File.join(cli.app_path, "node_modules")),
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

    def bundler_version
      index = @gemfile_lock.find_index("BUNDLED WITH")
      raise "Cannot find 'BUNDLED WITH' in 'Gemfile.lock'" unless index

      @gemfile_lock[index + 1].strip
    end

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
