#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./new.rb
# ./new.rb file-name-with-options
# NO_SAVE=1 ./new.rb file-name-with-options

require_relative "src/ask"

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
    skip_if: ->(gopt, ropt) { gopt[:rails_version] < 7 || ropt["api"] || ropt["skip-javascript"] },
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
    skip_if: ->(gopt, ropt) { gopt[:rails_version] >= 7 || ropt["api"] || ropt["skip-javascript"] },
  },
  js_bundler: {
    label: "Bundler for JavaScript",
    type: :one_of,
    variants: {
      "bun" => "Bun",
      "esbuild" => "esbuild",
      "importmap" => "importmap", # importmap is not a bundler, actually - it doesn't require Node.js
      "rollup" => "Rollup",
      "webpack" => "Webpack",
    },
    default: ->(_, _) { "importmap" },
    apply: ->(_gopt, ropt, val) { ropt["javascript"] = val },
    skip_if: ->(gopt, ropt) { gopt[:rails_version] < 7 || ropt["api"] || ropt["skip-javascript"] },
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
    skip_if: ->(gopt, ropt) { gopt[:rails_version] >= 7 || ropt["api"] || ropt["skip-javascript"] },
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
    apply: ->(gopt, ropt, val) do
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
}

class CLI
  def initialize(argv)
    @option_values_from_file = read_option_values_from_file(argv[0])
    @generator_option_values = {}
    @rails_option_values = {}
    @ask = Ask.new(@generator_option_values, @rails_option_values)
  end

  def call
    OPTIONS.each do |key, definition|
      if definition.key?(:skip_if)
        next if definition[:skip_if].call(@generator_option_values, @rails_option_values)
      end

      @generator_option_values[key] =
        if @option_values_from_file.key?(key)
          case definition[:type]
          when :boolean
            string_to_boolean(@option_values_from_file[key])
          when :many_of
            string_to_array(@option_values_from_file[key])
          else
            @option_values_from_file[key]
          end
        else
          puts
          @ask.question(definition)
        end

      @generator_option_values[key] = @generator_option_values[key].to_i if key == :rails_version

      definition[:apply]&.call(
        @generator_option_values,
        @rails_option_values,
        @generator_option_values[key]
      )
    end

    results = @generator_option_values.each_with_object("".dup) do |(key, value), acc|
      value = value.join(", ") if value.is_a?(Array)
      acc << "#{key}: #{value}\n"
    end

    if ENV.fetch("NO_SAVE", "0") == "0"
      puts "", "Ready to use these options:", results, ""

      if @ask.yes?(label: "Save option values into file?", default: ->(_, _) { "y" })
        file_name = @ask.line(label: "File path")
        File.write(file_name, results)
      end
    end
  end

  def read_option_values_from_file(file_name)
    return {} if file_name.nil? || file_name.empty?

    File.readlines(file_name).to_h do |line|
      k, v = line.split(":", 2).map(&:strip)
      [k.to_sym, v]
    end
  end

  def string_to_array(str)
    str.split(",").map(&:strip)
  end

  def string_to_boolean(str)
    str == "true" ? true : (str == "false" ? false : raise(ArgumentError, str))
  end

  def install_railties
    @rails_version = Gem::Requirement.new("~> #{@generator_option_values[:rails_version]}")

    # Example: gem install -N --backtrace --version '~> 7' railties
    Gem.install("railties", @rails_version, document: [])
  end

  def generate_app
    railties_bin_path = Gem.bin_path("railties", "rails", @rails_version)
    railties_path = railties_bin_path.delete_suffix("/exe/rails")

    require "#{railties_path}/lib/rails/ruby_version_check"
    require "#{railties_path}/lib/rails/command"

    # First item has higher priority than the last one.
    # Rails application generator uses $LOAD_PATH for autoloading classes and modules.
    $LOAD_PATH.unshift("#{railties_path}/lib")

    # system("#{railties_bin_path} #{args_for_rails_new.join(" ")}")
    Rails::Command.invoke :application, args_for_rails_new
  end

  def args_for_rails_new
    args = ["new", File.expand_path(@generator_option_values[:app_path], __dir__)]

    @rails_option_values.each do |k, v|
      next if v == false

      args << (v == true ? "--#{k}" : "--#{k}=#{v}")
    end

    args
  end

  def add_postinstall_steps
    @postinstall = PostInstallScript.new(@generator_option_values)
    @postinstall.add_steps
  end

  def has_postinstall_steps?
    @postinstall.has_steps?
  end

  def run_postinstall_script
    @postinstall.create

    if @generator_option_values[:bundle_install]
      # Remove script if it succeeds.
      @postinstall.run && @postinstall.remove
    else
      puts "You should run `bundle install` and then `bin/postinstall` within application directory."
    end
  end
end

class PostInstallScript
  def initialize(generator_option_values)
    @generator_option_values = generator_option_values
    @app_path = File.expand_path(@generator_option_values[:app_path], __dir__)
    @file_name = "bin/postinstall"
    @steps = []
  end

  def add_steps
    add_front_end_libs
    remove_keeps
  end

  def has_steps?
    !@steps.empty?
  end

  def create
    text = <<~TEXT
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      #{@steps.join("\n\n")}
    TEXT

    Dir.chdir(@app_path) do
      File.write(@file_name, text)
      File.chmod(0o755, @file_name) # rwxr-xr-x
    end
  end

  def run
    Dir.chdir(@app_path) { system(@file_name) }
  end

  def remove
    Dir.chdir(@app_path) { File.unlink(@file_name) }
  end

  private

  def add_front_end_libs
    front_end_libs = @generator_option_values[:front_end_lib] || []
    front_end_libs.shift # First item has been already initialized.
    return if front_end_libs.empty?

    commands =
      front_end_libs
        .map { |lib| "system(\"bin/rails webpacker:install:#{lib}\") or exit(1)" }
        .join("\n  ")

    @steps << <<~TEXT
      puts "Adding front-end libraries..."
      Dir.chdir(File.dirname(__dir__)) do
        #{commands}
      end
    TEXT
  end

  def remove_keeps
    return if @generator_option_values[:keeps]

    keep_file_path = File.join(@app_path, "vendor/javascript/.keep")
    return unless File.exist?(keep_file_path)

    @steps << <<~RUBY
      puts "Remove vendor/javascript/.keep..."
      Dir.chdir(File.dirname(__dir__)) do
        File.unlink("vendor/javascript/.keep") if File.exist?("vendor/javascript/.keep")
        if Dir.empty?("vendor/javascript")
          Dir.delete("vendor/javascript")
          if File.exist?("app/assets/config/manifest.js")
            lines = File.readlines("app/assets/config/manifest.js")
            lines -= ["//= link_tree ../../../vendor/javascript .js\\n"]
            File.write("app/assets/config/manifest.js", lines.join)
          end
        end
      end
    RUBY
  end
end

begin
  cli = CLI.new(ARGV)

  puts "Press Ctrl+C to stop anytime."
  cli.call

  puts "Installing railties gem..."
  cli.install_railties

  puts "Generating application..."
  cli.generate_app
  cli.add_postinstall_steps

  if cli.has_postinstall_steps?
    puts "Run postinstall script..."
    cli.run_postinstall_script
  end

  puts "Done!"
rescue Ask::Interrupt
  exit(2)
rescue StandardError => e
  warn "Current dir: #{Dir.pwd}", e.message, e.backtrace.grep_v(/ruby|bundle|gems/)
  exit(1)
end
