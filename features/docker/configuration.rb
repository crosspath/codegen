# frozen_string_literal: true

require "json"

require_relative "../../src/gemfile_lock"
require_relative "../../src/package_json"

module Features
  module Docker
    class Configuration < Feature
      def call
        @gemfile_lock = GemfileLock.new(cli.app_path)
        @package_json = PackageJson.new(cli.app_path)

        @includes_active_storage = active_storage?
        @dbms_adapter = read_dbms_adapter(read_database_yml)
        @includes_frontend = @package_json.exist?

        @includes_bun = @includes_frontend
        @includes_bun &&= project_file_exist?("bun.config.js") || project_file_exist?("bun.lockb")
        @includes_yarn = @includes_frontend && @package_json.package_manager =~ /^yarn@/
      end

      def dockerfile_variables
        @dockerfile_variables ||=
          {
            args: build_args,
            envs: build_envs,
            bun_version: "", # TODO
            bundler_version: @gemfile_lock.bundler_version,
            has_node_modules: project_file_exist?("node_modules"),
            includes_frontend: @includes_frontend,
            includes_propshaft: @gemfile_lock.includes?("propshaft"),
            includes_sprockets: @gemfile_lock.includes?("sprockets"),
            includes_bun: @includes_bun,
            includes_yarn: @includes_yarn,
            required_dirs:,
            bundle_config_ci: project_file_exist?(".bundle/config.ci"),
            bundle_config_dev: project_file_exist?(".bundle/config.development"),
            bundle_config_prod: project_file_exist?(".bundle/config.production"),
            use_bootsnap: @gemfile_lock.includes?("bootsnap"),
            runtime_packages:,
            build_time_packages:,
          }
      end

      def compose_variables
        {
          includes_redis: @gemfile_lock.includes?("redis"),
          includes_sidekiq: @gemfile_lock.includes?("sidekiq"),
          database: DBMS_IMAGES[@dbms_adapter],
        }
      end

      private

      CONFIG_APPLICATION_FILE = "config/application.rb"
      DATABASE_YML = "config/database.yml"
      RUBY_VERSION_FILE = ".ruby-version"

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
      }.freeze

      # For Alpine.
      DBMS_PACKAGES = {
        "mysql" => {build: %w[mariadb-dev], runtime: %w[mariadb-client]},
        "postgresql" => {build: %w[libpq-dev], runtime: %w[postgresql16-client]},
        "sqlite3" => {build: %w[sqlite-dev], runtime: %w[sqlite]},
      }.freeze

      REQUIRED_DIRS = %w[.bundle log tmp/pids].freeze
      REQUIRED_DIRS_FOR_STORAGE = %w[storage tmp/storage].freeze

      ENV_JEMALLOC = {
        LD_PRELOAD: "libjemalloc.so.2",
        MALLOC_CONF: %w[
          background_thread:true
          metadata_thp:auto
          dirty_decay_ms:5000
          muzzy_decay_ms:5000
          narenas:2
        ].join(",").freeze,
      }.freeze

      private_constant :CONFIG_APPLICATION_FILE, :DATABASE_YML
      private_constant :RUBY_VERSION_FILE, :DBMS_IMAGES, :DBMS_PACKAGES
      private_constant :REQUIRED_DIRS, :REQUIRED_DIRS_FOR_STORAGE, :ENV_JEMALLOC

      def build_args
        {
          RUBY_VERSION: read_ruby_version, # Example: 3.3.4
        }
      end

      def build_envs
        ENV_JEMALLOC.map { |k, v| "    #{k}=#{v}" }
      end

      def required_dirs
        res = REQUIRED_DIRS.dup
        res += REQUIRED_DIRS_FOR_STORAGE if @includes_active_storage
        res.sort
      end

      def runtime_packages
        res = []
        res += DBMS_PACKAGES.dig(@dbms_adapter, :runtime) || [] if @dbms_adapter
        res << "vips" if @includes_active_storage

        # if add_chromium
        #   Best solution: use container with headless Chrome/Chromium only and pass it a URL
        #   to page with generated content (available in Docker internal network only).
        #   @see https://developer.chrome.com/blog/headless-chrome
        #   @see https://github.com/Zenika/alpine-chrome
        #   Debian packages:
        #     libasound2 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libcups2 libdbus-1-3
        #     libgtk-3-0 libnspr4 libnss3 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1
        #     libxfixes3 libxi6 libxrandr2 libxss1 libxtst6
        # end

        # Add icu-data-full ?

        res
      end

      def build_time_packages
        res = []
        res += DBMS_PACKAGES.dig(@dbms_adapter, :build) || [] if @dbms_adapter
        res << "nodejs npm" if @includes_yarn
        res << "unzip" if @includes_bun
        res
      end

      def active_storage?
        config_application_rb = read_project_file(CONFIG_APPLICATION_FILE).split("\n")

        config_application_rb.any? do |line|
          line.start_with?('require "rails/all"', 'require "active_storage/engine"')
        end
      end

      def add_chromium?
        cli.ask.question(
          type: :boolean,
          label: "Add packages for Chromium",
          default: ->(_, _) { "n" }
        )
      end

      def read_database_yml
        project_file_exist?(DATABASE_YML) ? read_project_file(DATABASE_YML).lines : nil
      end

      def read_dbms_adapter(config_database_yml)
        adapter_line = config_database_yml&.find { |line| line.strip.start_with?("adapter:") }
        return unless adapter_line

        adapter_line.split(":", 2).last.sub(/#.*/, "").strip
      end

      def read_ruby_version
        return RUBY_VERSION unless project_file_exist?(RUBY_VERSION_FILE)

        read_project_file(RUBY_VERSION_FILE).strip.sub("ruby-", "")
      end
    end
  end
end
