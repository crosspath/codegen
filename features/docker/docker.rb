# frozen_string_literal: true

require "json"

module Features
  # @see Dockerfile syntax: https://docs.docker.com/engine/reference/builder/
  # @see https://github.com/rails/rails/blob/main/railties/lib/rails/generators/app_base.rb
  class Docker < Feature
    register_as "docker"

    def call
      read_project_files

      if project_file_exist?("Dockerfile")
        puts "Updating Dockerfile..."
        update_dockerfile

        puts "Creating Dockerfile for development..."
        create_dockerfile_dev
      else
        puts "Creating Dockerfiles..."
        create_dockerfiles
      end

      puts "Creating files for Docker Compose..."
      create_compose_files

      puts "Updating .dockerignore file..."
      update_dockerignore
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

    # For Debian.
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
      "/app/assets/builds/*",
      "/config/master.key",
      "/config/credentials/*.key",
      "/log/*",
      "/tmp/*",
    ].freeze

    IGNORE_FILE_ENTRIES_FOR_ASSETS = [
      "/node_modules/",
      "/public/assets",
    ].freeze

    IGNORE_FILE_ENTRIES_FOR_STORAGE = [
      "/storage/*",
    ].freeze

    PACKAGE_JSON = "package.json"
    DATABASE_YML = "config/database.yml"

    APPEND_LINES =
      <<~DOCKERFILE
        # Sendmail
        ARG SSMTP_RELAY_HOST_PORT
        RUN sed -i "s/mailhub=mail/mailhub=${SSMTP_RELAY_HOST_PORT}/" /etc/ssmtp/ssmtp.conf

        # Russian CAs
        RUN wget --quiet https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt \\
            -O /usr/local/share/ca-certificates/russian_trusted_root_ca_pem.crt && \\
            /usr/sbin/update-ca-certificates

        RUN groupadd -g 1000 app && \\
            useradd -u 1000 -g 1000 -m app --shell /bin/bash

        # Application directory: /rails
        RUN mkdir -m 0755 /rails
      DOCKERFILE

    USE_COREPACK =
      <<~DOCKERFILE
        RUN --mount=type=cache,uid=1000,target=/rails \\
            npm install -g corepack && \\
            corepack enable
      DOCKERFILE

    SPACE = " "

    attr_reader(
      :config_database_yml,
      :dbms_adapter,
      :dockerfile_variables,
      :gemfile_lock,
      :redis,
      :sidekiq
    )

    def read_project_files
      @gemfile_lock = read_project_file("Gemfile.lock").split("\n")

      package_json =
        project_file_exist?(PACKAGE_JSON) ? JSON.parse(read_project_file(PACKAGE_JSON)) : nil

      @config_database_yml =
        project_file_exist?(DATABASE_YML) ? read_project_file(DATABASE_YML).lines : nil

      @config_application_rb = read_project_file("config/application.rb").split("\n")

      ruby_version = read_project_file(".ruby-version").strip
      bundler_version = read_bundler_version
      @dbms_adapter = read_dbms_adapter
      @redis = !@gemfile_lock.grep(/^\s*redis\s/).empty?
      @sidekiq = !@gemfile_lock.grep(/^\s*sidekiq\s/).empty?

      @dockerfile_variables = {
        ruby_version:,
        bundler_version:,
        includes_frontend: !package_json.nil?,
        includes_bun: !package_json.nil? && project_file_exist?("bun.config.js"),
        includes_yarn: !package_json.nil? && package_json["packageManager"] =~ /^yarn@/,
        add_chromium: cli.ask.yes?(label: "Add packages for Chromium", default: ->(_, _) { "n" }),
        database_packages: DBMS_PACKAGES[dbms_adapter],
        includes_active_storage: active_storage?,
        includes_sidekiq: sidekiq,
        has_node_modules: Dir.exist?(File.join(cli.app_path, "node_modules")),
        bundle_config_dev: project_file_exist?(".bundle/config.development"),
        bundle_config_prod: project_file_exist?(".bundle/config.production"),
      }
    end

    def update_dockerfile
      dockerfile = read_project_file("Dockerfile").split("\n")

      add_packages_after = dockerfile.find_index { |line| line.start_with?("FROM") }
      unless add_packages_after
        raise "Cannot find \"FROM\" statement in Dockerfile. Is this file corrupted?"
      end

      dockerfile.insert(add_packages_after + 1, *preparation_entries, "", APPEND_LINES.rstrip)

      workdir_index = dockerfile.find_index { |line| line == "WORKDIR /rails" }
      dockerfile.insert(workdir_index + 1, *after_workdir)

      # Remove section with RAILS_ENV and BUNDLE_*.
      env_index = dockerfile.find_index { |line| line.start_with?("ENV RAILS_ENV") }
      env_index -= 1 if dockerfile[env_index - 1].start_with?("#")
      env_last_index = dockerfile[(env_index + 1)..].find_index(&:empty?) + env_index
      env_last_index.downto(env_index) { |index| dockerfile.delete_at(index) }

      # The first line with "apt-get install" relates to "build" stage.
      # The second line with "apt-get install" relates to "deploy" stage (not changed here).
      apt_install_index = dockerfile.find_index { |line| line.include?("apt-get install") }
      parts = dockerfile[apt_install_index].split("apt-get install --no-install-recommends -y", 2)
      packages = parts[1].strip.split(SPACE)

      # Do not build Node.js from source.
      packages -= ["node-gyp", "python-is-python3"]
      packages << "${PACKAGES}"

      dockerfile[apt_install_index] =
        [parts[0], packages.join(" ")].join("apt-get install --no-install-recommends -y ")

      node_version_index = dockerfile.find_index { |line| line.start_with?("ARG NODE_VERSION") }
      if node_version_index
        next_empty_line_index = dockerfile[(node_version_index + 1)..].find_index(&:empty?)
        node_install_last_index = next_empty_line_index + node_version_index
        node_install_last_index.downto(node_version_index) { |index| dockerfile.delete_at(index) }
        dockerfile.insert(node_version_index, USE_COREPACK.rstrip)
      end

      # Use `.bundle/config` during `bundle install` if this file exists.
      gemfile_index = dockerfile.find_index { |line| line.start_with?("COPY Gemfile") }
      dockerfile.insert(gemfile_index, 'ENV RAILS_ENV="production"')
      if dockerfile_variables[:bundle_config_prod]
        dockerfile.insert(gemfile_index + 1, "COPY .bundle/config.production .bundle/config")
      end

      copy_project_tree_index = dockerfile.find_index { |line| line == "COPY . ." }
      has_copy_project_comment = dockerfile[copy_project_tree_index - 1].start_with?("#")

      last_from_index = dockerfile.find_index { |line| line == "FROM base" }
      last_from_index -= 1 if dockerfile[last_from_index - 1].start_with?("#")

      extract_lines = dockerfile[(copy_project_tree_index + 1)...last_from_index]
      top_index = copy_project_tree_index - (has_copy_project_comment ? 1 : 0)
      (last_from_index - 1).downto(top_index) { |index| dockerfile.delete_at(index) }

      copy_from_build_index = dockerfile.find_index { |line| line.start_with?("COPY --from=build") }
      dockerfile.insert(copy_from_build_index, "COPY . .")

      copy_vendor_bundle = "COPY --from=build /rails/vendor/bundle /rails/vendor/bundle"
      dockerfile.insert(copy_from_build_index + 1, copy_vendor_bundle)

      rev_index = dockerfile.reverse.find_index { |line| line.start_with?("COPY --from=build") }
      last_copy_from_build_index = dockerfile.size - rev_index

      entrypoint_index = dockerfile.find_index { |line| line.start_with?("ENTRYPOINT") }
      entrypoint_index -= 1 if dockerfile[entrypoint_index - 1].start_with?("#")

      line_with_chown = dockerfile.find { |line| line.lstrip.start_with?("chown -R rails:rails") }
      chown = line_with_chown.sub("rails:rails", "app:app").strip

      (entrypoint_index - 1).downto(last_copy_from_build_index + 1) do |index|
        dockerfile.delete_at(index)
      end

      if dockerfile_variables[:includes_sidekiq]
        extract_lines.unshift("RUN bin/rails sidekiq:merge_configs")
      end

      as_user = ["", "RUN #{chown}", "", "USER app", ""]
      dockerfile.insert(last_copy_from_build_index + 1, *(extract_lines + as_user))

      # Change more than 1 sequential empty lines to 1 empty line.
      index = 0
      loop do
        break if index + 1 == dockerfile.size

        if dockerfile[index].empty? && dockerfile[index + 1].empty?
          dockerfile.delete_at(index)
        else
          index += 1
        end
      end

      # Empty new line at end of file.
      dockerfile << "" unless dockerfile.last.empty?

      write_project_file("Dockerfile", dockerfile.join("\n"))
    end

    def create_dockerfile_dev
      erb("Dockerfile.development", "Dockerfile.development", **dockerfile_variables)
    end

    def create_dockerfiles
      erb("Dockerfile", "Dockerfile", **dockerfile_variables)
      create_dockerfile_dev
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

    def preparation_entries
      entries = [
        "",
        'ARG PACKAGES="cmake libjemalloc2 ssmtp"',
        'ARG PACKAGES="${PACKAGES} iproute2 less net-tools nano screen telnet tmux vim"',
      ]

      entries << 'ARG PACKAGES="${PACKAGES} nodejs npm"' if dockerfile_variables[:includes_yarn]

      # Use it if you want to build Node.js from sources, not to use binaries from APT repos.
      # And add build step for Node.js.
      # if dockerfile_variables[:includes_yarn]
      #   entries << 'ARG PACKAGES="${PACKAGES} node-gyp python-is-python3"'
      # end

      if dockerfile_variables[:add_chromium]
        entries <<
          'ARG PACKAGES="${PACKAGES} libasound2 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 ' \
            'libcups2 libdbus-1-3 libgtk-3-0 libnspr4 libnss3 libx11-xcb1 libxcomposite1 ' \
            'libxcursor1 libxdamage1 libxfixes3 libxi6 libxrandr2 libxss1 libxtst6"'
      end

      if dockerfile_variables[:includes_active_storage]
        entries << 'ARG PACKAGES="${PACKAGES} libvips"'
      end

      entries
    end

    def after_workdir
      entries = ["RUN mkdir -p -m 0755 .bundle log tmp/pids vendor/bundle && \\"]

      if dockerfile_variables[:includes_active_storage]
        entries << "    mkdir -p -m 0755 storage tmp/storage && \\"
      end

      entries << "    chown -R app:app ."
      entries
    end

    def update_dockerignore
      entries = IGNORE_FILE_ENTRIES
      entries += IGNORE_FILE_ENTRIES_FOR_ASSETS if dockerfile_variables[:includes_frontend]
      entries += IGNORE_FILE_ENTRIES_FOR_STORAGE if dockerfile_variables[:includes_active_storage]
      update_ignore_file(".dockerignore", add: entries)
    end
  end
end
