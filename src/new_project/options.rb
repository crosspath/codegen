# frozen_string_literal: true

module NewProject
  module Options
    # Types:
    #
    # GeneratorOptionName ::= Symbol
    # RailsOptionName ::= String
    # OptionValue ::= String | true | false | Array(String)
    # GeneratorOptions ::= Hash(GeneratorOptionName, OptionValue)
    # RailsOptions ::= Hash(RailsOptionName, OptionValue)
    # OptionDefinition ::= Hash {
    #   label: String,
    #   type: :text | :boolean | :one_of | :many_of,
    #   variants: Hash(String, String), # if type == :one_of || type == :many_of
    #   default: Proc(GeneratorOptions, RailsOptions) -> OptionValue, # optional
    #   apply: Proc(GeneratorOptions, RailsOptions, OptionValue), # optional
    #   skip_if: Proc(GeneratorOptions, RailsOptions) -> true | false # optional
    # }
    # typeof OPTIONS == Hash(Symbol, OptionDefinition)
    OPTIONS = {
      rails_version: {
        label: "Rails version",
        type: :one_of,
        variants: {
          "6" => "Rails 6",
          "7" => "Rails 7",
        },
        default: ->(_, _) { "7" },
      },
      app_path: {
        label: "Application path",
        type: :text,
      },
      name: {
        label: "Application name",
        type: :text,
        default: ->(gopt, _ropt) do
          File.basename(gopt[:app_path])
        rescue StandardError
          ""
        end,
        apply: ->(_gopt, ropt, val) { ropt["name"] = val },
        skip_if: ->(gopt, _ropt) { gopt[:rails_version] < 7 },
      },
      mode: {
        # @see railties/lib/rails/generators/rails/app/app_generator.rb
        # Minimal:
        #   skip-action-cable: true
        #   skip-action-mailer: true
        #   skip-action-mailbox: true
        #   skip-action-text: true
        #   skip-active-job: true
        #   skip-active-storage: true
        #   skip-bootsnap: true
        #   skip-dev-gems: true
        #   skip-javascript: true (if webpack is disabled)
        #   skip-jbuilder: true
        #   skip-spring: true (Rails 6)
        #   skip-system-test: true (Rails 6)
        #   skip-webpack-install: true (if webpack is disabled) (Rails 6)
        #   skip-turbolinks: true (Rails 6)
        #   skip-hotwire: true (Rails 7)
        # API:
        #   skip-system-test: true (do not add gems: webdriver, selenium, capybara)
        #   skip-sprockets: true (Rails 6)
        #   skip-asset-pipeline: true (Rails 7)
        #   skip-javascript: true
        label: "Application template",
        type: :one_of,
        variants: {
          "full-stack" => "Full Stack (Ruby on Rails + front-end + mailers + etc)",
          "minimal" => "Minimal (Ruby on Rails + front-end)",
          "api-only" => "API-only (no app/assets, app/helpers)",
        },
        default: ->(_, _) { "full-stack" },
        apply: ->(_gopt, ropt, val) do
          case val
          when "full-stack" then next
          when "minimal" then ropt["minimal"] = true
          when "api-only" then ropt["api"] = true
          end
        end,
      },
      active_record: {
        label: "Add Active Record - Rails ORM",
        type: :boolean,
        default: ->(_, _) { true },
        apply: ->(_gopt, ropt, val) { ropt["skip-active-record"] = !val },
      },
      db: {
        label: "Database",
        type: :one_of,
        variants: {
          "mysql" => "MySQL (gem mysql2)",
          "trilogy" => "MySQL (gem trilogy)",
          "postgresql" => "PostgreSQL",
          "sqlite3" => "SQLite3",
          "oracle" => "Oracle",
          "sqlserver" => "SQLServer",
          "jdbcmysql" => "JDBC + Mysql",
          "jdbcsqlite3" => "JDBC + SQLite3",
          "jdbcpostgresql" => "JDBC + PostgreSQL",
          "jdbc" => "JDBC + other",
          "other" => "... other", # Required: gem name.
        },
        default: ->(_, _) { "postgresql" },
        apply: ->(_gopt, ropt, val) do
          ropt["database"] = val if val != "other"
        end,
        skip_if: ->(_gopt, ropt) { ropt["skip-active-record"] },
      },
      db_gem: {
        label: "Gem name for database",
        type: :text,
        apply: ->(_gopt, ropt, val) { ropt["database"] = val },
        skip_if: ->(gopt, ropt) { ropt["skip-active-record"] || gopt[:db] != "other" },
      },
      js: {
        label: "Add JavaScript",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) { ropt["skip-javascript"] = !val },
        skip_if: ->(_gopt, ropt) { ropt["api"] },
      },
      dev_gems: {
        label: "Add gems for development - web-console, rack-mini-profiler",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) { ropt["skip-dev-gems"] = !val },
        skip_if: ->(_gopt, ropt) { ropt["api"] },
      },
      keeps: {
        label: "Files .keep in directories: */concerns, lib/tasks, log, tmp",
        type: :boolean,
        default: ->(_, _) { false },
        apply: ->(_gopt, ropt, val) { ropt["skip-keeps"] = !val },
      },
      mailer: {
        label: "Add Action Mailer - send emails",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-action-mailer"] = true if val
          else
            ropt["skip-action-mailer"] = true unless val
          end
        end,
      },
      mailbox: {
        label: "Add Action Mailbox - receive emails",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-action-mailbox"] = true if val
          else
            ropt["skip-action-mailbox"] = true unless val
          end
        end,
      },
      action_text: {
        label: "Add Action Text - embedded HTML editor",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-action-text"] = true if val
          else
            ropt["skip-action-text"] = true unless val
          end
        end,
        skip_if: ->(_gopt, ropt) { ropt["api"] || ropt["skip-javascript"] },
      },
      active_job: {
        label: "Add Active Job - queue manager",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-active-job"] = true if val
          else
            ropt["skip-active-job"] = true unless val
          end
        end,
      },
      active_storage: {
        label: "Add Active Storage - file uploader",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-active-storage"] = true if val
          else
            ropt["skip-active-storage"] = true unless val
          end
        end,
      },
      action_cable: {
        label: "Add Action Cable - WebSockets support",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-active-cable"] = true if val
          else
            ropt["skip-active-cable"] = true unless val
          end
        end,
      },
      assets: {
        label: "Add asset pipeline - if you reject it, you still may add bundler for JavaScript",
        type: :boolean,
        default: ->(_, _) { true },
        apply: ->(gopt, ropt, val) do
          if gopt[:rails_version] < 7
            ropt["skip-sprockets"] = !val
          else
            ropt["skip-asset-pipeline"] = !val
          end
        end,
        skip_if: ->(_gopt, ropt) { ropt["api"] },
      },
      assets_lib: {
        label: "Library for asset pipeline",
        type: :one_of,
        variants: {
          "sprockets" => "Sprockets",
          "propshaft" => "Propshaft",
        },
        default: ->(_, _) { "sprockets" },
        apply: ->(_gopt, ropt, val) { ropt["asset-pipeline"] = val },
        skip_if: ->(gopt, ropt) do
          ropt["api"] || gopt[:rails_version] < 7 || ropt["skip-asset-pipeline"]
        end,
      },
      hotwire: {
        label: "Add Hotwire",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-hotwire"] = true if val
          else
            ropt["skip-hotwire"] = true unless val
          end
        end,
        skip_if: ->(gopt, ropt) do
          gopt[:rails_version] < 7 || ropt["api"] || ropt["skip-javascript"]
        end,
      },
      turbolinks: {
        label: "Add Turbolinks",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-turbolinks"] = true if val
          else
            ropt["skip-turbolinks"] = true unless val
          end
        end,
        skip_if: ->(gopt, ropt) do
          gopt[:rails_version] >= 7 || ropt["api"] || ropt["skip-javascript"]
        end,
      },
      js_bundler: {
        label: "Bundler for JavaScript",
        type: :one_of,
        variants: {
          "bun" => "Bun",
          "esbuild" => "esbuild",
          # importmap is not a bundler, actually - it doesn't require Node.js
          "importmap" => "importmap",
          "rollup" => "Rollup",
          "webpack" => "Webpack",
        },
        default: ->(_, _) { "importmap" },
        apply: ->(_gopt, ropt, val) { ropt["javascript"] = val },
        skip_if: ->(gopt, ropt) do
          gopt[:rails_version] < 7 || ropt["api"] || ropt["skip-javascript"]
        end,
      },
      css_lib: {
        label: "Library for CSS",
        type: :one_of,
        variants: {
          "none" => "None of these",
          "bootstrap" => "Bootstrap",
          "bulma" => "Bulma", # https://bulma.io/documentation/overview/
          "postcss" => "PostCSS",
          "sass" => "Sass",
          "tailwind" => "Tailwind",
        },
        default: ->(_, _) { "none" },
        apply: ->(_gopt, ropt, val) do
          ropt["css"] = val if val != "none"
        end,
        skip_if: ->(gopt, ropt) { gopt[:rails_version] < 7 || ropt["api"] || !gopt[:assets] },
      },
      webpacker: {
        label: "Add Webpacker - Rails wrapper for JavaScript bundler",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-webpack-install"] = true if val
          else
            ropt["skip-webpack-install"] = true unless val
          end
        end,
        skip_if: ->(gopt, ropt) do
          gopt[:rails_version] >= 7 || ropt["api"] || ropt["skip-javascript"]
        end,
      },
      front_end_lib: {
        label: "Libraries for front-end",
        type: :many_of,
        variants: {
          "angular" => "Angular",
          "coffee" => "CoffeeScript",
          "elm" => "Elm",
          "erb" => "ERB",
          "react" => "React",
          "stimulus" => "Stimulus",
          "svelte" => "Svelte",
          "typescript" => "TypeScript",
          "vue" => "Vue",
        },
        default: ->(_, _) { ["erb"] },
        apply: ->(_gopt, ropt, val) do
          ropt["webpack"] = val[0] # First item only.
        end,
        skip_if: ->(gopt, ropt) do
          gopt[:rails_version] >= 7 || ropt["api"] || ropt["skip-javascript"] || !gopt[:webpacker]
        end,
      },
      spring: {
        label: "Add Spring",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-spring"] = true if val
          else
            ropt["skip-spring"] = true unless val
          end
        end,
        skip_if: ->(gopt, _ropt) { gopt[:rails_version] >= 7 },
      },
      jbuilder: {
        label: "Add jbuilder",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-jbuilder"] = true if val
          else
            ropt["skip-jbuilder"] = true unless val
          end
        end,
      },
      bootsnap: {
        label: "Add Bootsnap",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-bootsnap"] = true if val
          else
            ropt["skip-bootsnap"] = true unless val
          end
        end,
      },
      tests: {
        label: "Add tests - Minitest",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-test"] = true if val
          else
            ropt["skip-test"] = true unless val
          end
        end,
      },
      system_tests: {
        label: "Add system tests - Capybara, Selenium",
        type: :boolean,
        default: ->(_gopt, ropt) { !ropt["minimal"] },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-system-test"] = true if val
          else
            ropt["skip-system-test"] = true unless val
          end
        end,
        skip_if: ->(gopt, ropt) { ropt["api"] || gopt[:tests] },
      },
      bundle_install: {
        label: "Run `bundle install` at the end of this process",
        type: :boolean,
        default: ->(_, _) { true },
        apply: ->(_gopt, ropt, val) { ropt["skip-bundle"] = !val },
      },
      # namespace: {
      #   label: "Skip namespace",
      #   type: :boolean,
      #   default: ->(_, _) { false },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-namespace"] = !val },
      # },
      # collision_check: {
      #   label: "Skip collision check",
      #   type: :boolean,
      #   default: ->(_, _) { false },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-collision-check"] = !val },
      # },
      # listen: {
      #   label: "Add `listen` gem",
      #   type: :boolean,
      #   default: ->(_, _) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-listen"] = !val },
      # },
      # puma: {
      #   label: "Add Puma",
      #   type: :boolean,
      #   default: ->(_, _) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-puma"] = !val },
      # },
      # git: {
      #   label: "Create .gitignore",
      #   type: :boolean,
      #   default: ->(_, _) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-git"] = !val },
      # },
      # docker: {
      #   label: "Create files for Docker",
      #   type: :boolean,
      #   default: ->(_, _) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-docker"] = !val },
      # },
      # gemfile: {
      #   label: "Add Gemfile",
      #   type: :boolean,
      #   default: ->(_, _) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-gemfile"] = !val },
      # },
      # decrypted_diffs: {
      #   label: "Configure git to show decrypted diffs of encrypted credentials",
      #   type: :boolean,
      #   default: ->(_, _) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-decrypted-diffs"] = !val },
      #   skip_if: ->(gopt, _ropt) { gopt[:rails_version] < 7 },
      # },
    }.freeze
  end
end
