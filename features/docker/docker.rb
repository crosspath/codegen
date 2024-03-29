# frozen_string_literal: true

require "json"

module Features
  # @see Dockerfile syntax: https://docs.docker.com/engine/reference/builder/
  # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/app_base.rb
  class Docker < Feature
    register_as "docker"

    def call
      puts "Creating files for Docker..."
      read_project_files
      create_dockerfiles
      create_compose_files

      puts "Updating .dockerignore file..."
      update_ignore_file(".dockerignore", add: IGNORE_FILE_ENTRIES)
    end

    private

    DBMS_IMAGES = {
      # @see https://hub.docker.com/_/mysql
      "mysql" => {
        dbms: "mysql",
        image: "mysql:8",
        port: 3306,
        env: {"MYSQL_ROOT_PASSWORD" => "password"},
        data_path: "/var/lib/mysql",
      },
      # @see https://hub.docker.com/_/postgres
      "postgresql" => {
        dbms: "postgresql",
        image: "postgres:16",
        port: 5432,
        env: {"POSTGRES_PASSWORD" => "password"},
        data_path: "/var/lib/postgresql/data",
      },
      # "sqlite3",
      # "oracle",
      # "sqlserver",
      # "jdbcmysql",
      # "jdbcsqlite3",
      # "jdbcpostgresql",
      # "jdbc"
    }.freeze

    DBMS_PACKAGES = {
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

    # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/app/templates/dockerignore.tt
    IGNORE_FILE_ENTRIES = [
      "/.git/",
      "/config/master.key",
      "/config/credentials/*.key",
      "/log/*",
      "/tmp/*",
      "/storage/*",
      "/node_modules/",
      "/app/assets/builds/*",
      "/public/assets",
    ].freeze

    PACKAGE_JSON = "package.json"
    DATABASE_YML = "config/database.yml"

    attr_reader(
      :active_storage,
      :bundler_version,
      :config_database_yml,
      :dbms_adapter,
      :gemfile_lock,
      :package_json,
      :redis,
      :ruby_version,
      :sidekiq
    )

    def read_project_files
      @gemfile_lock = read_project_file("Gemfile.lock").split("\n")

      @package_json =
        project_file_exist?(PACKAGE_JSON) ? JSON.parse(read_project_file(PACKAGE_JSON)) : nil

      @config_database_yml =
        project_file_exist?(DATABASE_YML) ? read_project_file(DATABASE_YML).lines : nil

      @config_application_rb = read_project_file("config/application.rb").split("\n")

      @ruby_version = read_project_file(".ruby-version").strip
      @bundler_version = read_bundler_version
      @dbms_adapter = read_dbms_adapter
      @active_storage = active_storage?
      @redis = !@gemfile_lock.grep(/^\s*redis\s/).empty?
      @sidekiq = !@gemfile_lock.grep(/^\s*sidekiq\s/).empty?
    end

    def create_dockerfiles
      locals = {
        ruby_version:,
        bundler_version:,
        includes_frontend: !package_json.nil?,
        includes_bun: !package_json.nil? && project_file_exist?("bun.config.js"),
        includes_yarn: !package_json.nil? && package_json["packageManager"] =~ /^yarn@/,
        add_chromium: cli.ask.yes?(label: "Add packages for Chromium", default: ->(_, _) { "n" }),
        database_packages: DBMS_PACKAGES[dbms_adapter],
        includes_active_storage: active_storage,
        includes_sidekiq: sidekiq,
        has_node_modules: Dir.exist?(File.join(cli.app_path, "node_modules")),
        bundle_config_dev: project_file_exist?(".bundle/config.development"),
        bundle_config_prod: project_file_exist?(".bundle/config.production"),
      }

      erb("Dockerfile", "Dockerfile", **locals)
      erb("Dockerfile.development", "Dockerfile.development", **locals)
    end

    def create_compose_files
      locals = {
        includes_redis: redis,
        includes_sidekiq: sidekiq,
        database: DBMS_IMAGES[dbms_adapter],
      }

      erb("compose.yaml", "compose.yaml", **locals)
      erb("compose.development.yaml", "compose.development.yaml", **locals)
    end

    def read_bundler_version
      index = @gemfile_lock.find_index("BUNDLED WITH")
      raise "Cannot find 'BUNDLED WITH' in 'Gemfile.lock'" unless index

      @gemfile_lock[index + 1].strip
    end

    def read_dbms_adapter
      adapter_line = @config_database_yml&.find { |line| line.strip.start_with?("adapter:") }
      return unless adapter_line

      adapter_line.split(":", 2).last.sub(/#.*/, "").strip
    end

    def active_storage?
      @config_application_rb.any? do |line|
        line.start_with?('require "rails/all"', 'require "active_storage/engine"')
      end
    end
  end
end
