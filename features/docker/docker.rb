# frozen_string_literal: true

module Features
  class Docker < Feature
    register_as "docker"

    def call
      locals = {
        ruby_version: read_project_file(".ruby-version").strip,
        bundler_version: read_project_file("Gemfile.lock").match(/\nBUNDLED WITH\n\s*(\S+)/)[1],
        includes_frontend: project_file_exist?("package.json"),
        add_chromium: cli.ask.yes?(label: "Add packages for Chromium", default: ->(_, _) { "n" }),
      }

      if locals[:includes_frontend]
        locals[:yarn_version] =
          read_project_file("package.json").match(/\n  "packageManager": "yarn@([\w.-]+)"/)[1]
      end

      if project_file_exist?("config/database.yml")
        dbms = read_project_file("config/database.yml").match(/\n  adapter:([^\n#]+)/)[1].strip
        locals[:database_packages] = DMBS_PACKAGES[dbms] if DMBS_PACKAGES[dbms]
      end

      erb("Dockerfile", "", **locals)
    end

    private

    DMBS_PACKAGES = {
      "mysql",
      "postgresql" => "libpq-dev",
      "sqlite3",
      "oracle",
      "sqlserver",
      "jdbcmysql",
      "jdbcsqlite3",
      "jdbcpostgresql",
      "jdbc"
    }.freeze  
  end
end
