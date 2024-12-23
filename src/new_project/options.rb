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
      # Comment this block after dropping support for Rails 7 (do not delete it).
      rails_version: {
        label: "Rails version",
        type: :one_of,
        variants: {
          "7" => "Rails 7",
          "8" => "Rails 8",
        },
        default: ->(_, _) { "8" },
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
        #   skip-javascript: true
        #   skip-jbuilder: true
        #   skip-hotwire: true
        # API:
        #   skip-system-test: true (do not add gems: webdriver, selenium, capybara)
        #   skip-asset-pipeline: true
        #   skip-javascript: true
        label: "Application template",
        type: :one_of,
        variants: {
          "full-stack" => "Full Stack (Ruby on Rails + front-end + mailers + etc)",
          "minimal" => "Minimal (Ruby on Rails + front-end)",
          "api-only" => "API-only (no app/assets, app/helpers)",
        },
        default: ->(_gopt, _ropt) { "full-stack" },
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
        default: ->(_gopt, _ropt) { true },
        apply: ->(_gopt, ropt, val) { ropt["skip-active-record"] = !val },
      },
      db_7: {
        label: "Database",
        type: :one_of,
        variants: {
          "mysql" => "MySQL (gem mysql2)",
          "trilogy" => "MySQL (gem trilogy)",
          "postgresql" => "PostgreSQL",
          "sqlite3" => "SQLite3",
          "other" => "... other", # Required: gem name.
        },
        default: ->(_gopt, _ropt) { "postgresql" },
        apply: ->(_gopt, ropt, val) { ropt["database"] = val if val != "other" },
        skip_if: ->(gopt, ropt) { gopt[:rails_version] == "8" || ropt["skip-active-record"] },
      },
      db_8: {
        label: "Database",
        type: :one_of,
        variants: {
          "mariadb-mysql" => "MariaDB (gem mysql2)",
          "mariadb-trilogy" => "MariaDB (gem trilogy)",
          "mysql" => "MySQL (gem mysql2)",
          "trilogy" => "MySQL (gem trilogy)",
          "postgresql" => "PostgreSQL",
          "sqlite3" => "SQLite3",
          "other" => "... other", # Required: gem name.
        },
        default: ->(_gopt, _ropt) { "postgresql" },
        apply: ->(_gopt, ropt, val) { ropt["database"] = val if val != "other" },
        skip_if: ->(gopt, ropt) { gopt[:rails_version] == "7" || ropt["skip-active-record"] },
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
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) { ropt["skip-dev-gems"] = !val },
        skip_if: ->(_gopt, ropt) { ropt["api"] },
      },
      keeps: {
        label: "Files .keep in directories: */concerns, lib/tasks, log, tmp",
        type: :boolean,
        default: ->(_gopt, _ropt) { false },
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
        default: ->(_gopt, _ropt) { false },
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
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-action-cable"] = true if val
          else
            ropt["skip-action-cable"] = true unless val
          end
        end,
      },
      assets: {
        label: "Add asset pipeline - if you reject it, you still may add bundler for JavaScript",
        type: :boolean,
        default: ->(_gopt, _ropt) { true },
        apply: ->(_gopt, ropt, val) { ropt["skip-asset-pipeline"] = !val },
        skip_if: ->(_gopt, ropt) { ropt["api"] },
      },
      assets_lib: {
        label: "Library for asset pipeline",
        type: :one_of,
        variants: {
          "sprockets" => "Sprockets",
          "propshaft" => "Propshaft",
        },
        default: ->(_gopt, _ropt) { "sprockets" },
        apply: ->(_gopt, ropt, val) { ropt["asset-pipeline"] = val },
        skip_if: ->(gopt, ropt) do
          gopt[:rails_version] == "8" || ropt["api"] || ropt["skip-asset-pipeline"]
        end,
      },
      hotwire: {
        label: "Add Hotwire",
        type: :boolean,
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-hotwire"] = true if val
          else
            ropt["skip-hotwire"] = true unless val
          end
        end,
        skip_if: ->(_gopt, ropt) { ropt["api"] || ropt["skip-javascript"] },
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
        default: ->(_gopt, _ropt) { "importmap" },
        apply: ->(_gopt, ropt, val) { ropt["javascript"] = val },
        skip_if: ->(_gopt, ropt) { ropt["api"] || ropt["skip-javascript"] },
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
        default: ->(_gopt, _ropt) { "none" },
        apply: ->(_gopt, ropt, val) { ropt["css"] = val if val != "none" },
        skip_if: ->(gopt, ropt) { ropt["api"] || !gopt[:assets] },
      },
      jbuilder: {
        label: "Add jbuilder",
        type: :boolean,
        default: ->(_gopt, _ropt) { false },
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
        default: ->(_gopt, _ropt) { true },
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
        default: ->(_gopt, _ropt) { false },
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
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) do
          if ropt["minimal"]
            ropt["no-skip-system-test"] = true if val
          else
            ropt["skip-system-test"] = true unless val
          end
        end,
        skip_if: ->(gopt, ropt) { ropt["api"] || gopt[:tests] },
      },
      rubocop_omakase: {
        label: "Add RuboCop configration from Rails team (rubocop-rails-omakase)",
        type: :boolean,
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) { ropt["skip-rubocop"] = !val },
      },
      brakeman: {
        label: "Add Brakeman (you can add it later)",
        type: :boolean,
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) { ropt["skip-brakeman"] = !val },
      },
      github_actions: {
        label: "Add configuration for GitHub Actions (CI)",
        type: :boolean,
        default: ->(_gopt, _ropt) { true },
        apply: ->(_gopt, ropt, val) { ropt["skip-ci"] = !val },
      },
      # @see https://github.com/basecamp/thruster
      thruster: {
        label: "Add Thruster - HTTP/2 proxy (light-weight replacement for Nginx)",
        type: :boolean,
        default: ->(_gopt, _ropt) { true },
        apply: ->(_gopt, ropt, val) { ropt["skip-thruster"] = !val },
        skip_if: ->(gopt, _ropt) { gopt[:rails_version] == "7" },
      },
      # @see https://github.com/basecamp/kamal
      kamal: {
        label: "Add Kamal - tool for deployments",
        type: :boolean,
        default: ->(_gopt, _ropt) { true },
        apply: ->(_gopt, ropt, val) { ropt["skip-kamal"] = !val },
        skip_if: ->(gopt, _ropt) { gopt[:rails_version] == "7" },
      },
      # @see https://github.com/rails/solid_cable
      # @see https://github.com/rails/solid_cache
      # @see https://github.com/rails/solid_queue
      solid: {
        label: "Add Solid pack - Cable, Cache, Queue (Solid Cable won't install if you disabled " +
          "Action Cable)",
        type: :boolean,
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) { ropt["skip-solid"] = !val },
        skip_if: ->(gopt, _ropt) { gopt[:rails_version] == "7" },
      },
      bundle_install: {
        label: "Run `bundle install` at the end of this process",
        type: :boolean,
        default: ->(_gopt, _ropt) { false },
        apply: ->(_gopt, ropt, val) { ropt["skip-bundle"] = !val },
      },
      # namespace: {
      #   label: "Skip namespace",
      #   type: :boolean,
      #   default: ->(_gopt, _ropt) { false },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-namespace"] = !val },
      # },
      # collision_check: {
      #   label: "Skip collision check",
      #   type: :boolean,
      #   default: ->(_gopt, _ropt) { false },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-collision-check"] = !val },
      # },
      # git: {
      #   label: "Create .gitignore",
      #   type: :boolean,
      #   default: ->(_gopt, _ropt) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-git"] = !val },
      # },
      # docker: {
      #   label: "Create files for Docker",
      #   type: :boolean,
      #   default: ->(_gopt, _ropt) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-docker"] = !val },
      # },
      # decrypted_diffs: {
      #   label: "Configure git to show decrypted diffs of encrypted credentials",
      #   type: :boolean,
      #   default: ->(_gopt, _ropt) { true },
      #   apply: ->(_gopt, ropt, val) { ropt["skip-decrypted-diffs"] = !val },
      # },
      # ruby: {
      #   label: "Path to the Ruby binary",
      #   type: :text,
      #   default: ->(_gopt, _ropt) { `which ruby`.strip },
      #   apply: ->(_gopt, ropt, val) { ropt["ruby"] = val },
      # },
      # template: {
      #   label: "Path to some application template (can be a filesystem path or URL)",
      #   type: :text,
      #   default: ->(_gopt, _ropt) { "" },
      #   apply: ->(_gopt, ropt, val) { ropt["template"] = val },
      # },
      # devcontainer: {
      #   label: "Add .devcontainer files",
      #   type: :boolean,
      #   default: ->(_gopt, _ropt) { false },
      #   apply: ->(_gopt, ropt, val) { ropt["devcontainer"] = val },
      # },
    }.freeze
  end
end
