#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./new.rb
# ./new.rb file-name-with-options
# NO_SAVE=1 ./new.rb file-name-with-options

require "io/console"

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
      "1" => "Full Stack (Ruby on Rails + front-end + mailers + etc)",
      "2" => "Minimal (Ruby on Rails + front-end)",
      "3" => "API-only (no app/assets, app/helpers)",
    },
    default: ->(_, _) { "1" },
    apply: ->(_gopt, ropt, val) do
      case val
      when "1" then next
      when "2" then ropt["minimal"] = true
      when "3" then ropt["api"] = true
      end
    end,
  },
  active_record: {
    label: "Add Active Record - Rails ORM",
    type: :boolean,
    default: ->(_, _) { true },
    apply: ->(_gopt, ropt, val) { ropt["skip-action-record"] = !val },
  },
  db: {
    label: "Database",
    type: :one_of,
    variants: {
      "1" => "mysql",
      "2" => "postgresql",
      "3" => "sqlite3",
      "4" => "oracle",
      "5" => "sqlserver",
      "6" => "jdbcmysql",
      "7" => "jdbcsqlite3",
      "8" => "jdbcpostgresql",
      "9" => "jdbc",
      "0" => "... other", # Required: gem name.
    },
    default: ->(_, _) { "2" },
    apply: ->(_gopt, ropt, val) do
      ropt["database"] = OPTIONS[:db][:variants][val] unless val == "0"
    end,
    skip_if: ->(_gopt, ropt) { ropt["minimal"] || ropt["skip-action-record"] },
  },
  db_gem: {
    label: "Gem name for database",
    type: :text,
    apply: ->(_gopt, ropt, val) { ropt["database"] = val },
    skip_if: ->(gopt, ropt) { ropt["minimal"] || ropt["skip-action-record"] || gopt[:db] != "0" },
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
    label: "Add asset pipeline",
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
      "1" => "Sprockets",
      "2" => "Propshaft",
    },
    default: ->(_, _) { "1" },
    apply: ->(_gopt, ropt, val) do
      ropt["asset-pipeline"] = OPTIONS[:assets_lib][:variants][val].downcase
    end,
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
      "e" => "esbuild",
      "i" => "importmap", # importmap is not a bundler, actually - it doesn't require Node.js
      "r" => "Rollup",
      "w" => "Webpack",
    },
    default: ->(_, _) { "i" },
    apply: ->(_gopt, ropt, val) do
      ropt["javascript"] = OPTIONS[:js_bundler][:variants][val].downcase
    end,
    skip_if: ->(gopt, ropt) { gopt[:rails_version] < 7 || ropt["api"] || ropt["skip-javascript"] },
  },
  css_lib: {
    label: "Library for CSS",
    type: :one_of,
    variants: {
      "1" => "None of these",
      "2" => "Bootstrap",
      "3" => "Bulma", # https://bulma.io/documentation/overview/
      "4" => "PostCSS",
      "5" => "Sass",
      "6" => "Tailwind",
    },
    default: ->(_, _) { "1" },
    apply: ->(_gopt, ropt, val) do
      ropt["css"] = OPTIONS[:css_lib][:variants][val].downcase unless val == "1"
    end,
    skip_if: ->(gopt, ropt) { gopt[:rails_version] < 7 || ropt["api"] || !gopt[:assets] },
  },
  webpacker: {
    label: "Add Webpacker",
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
      "a" => "Angular",
      "c" => "Coffee",
      "e" => "ERB",
      "l" => "Elm",
      "r" => "React",
      "s" => "Svelte",
      "t" => "Stimulus",
      "v" => "Vue",
    },
    default: ->(_, _) { "e" },
    apply: ->(gopt, ropt, val) do
      ropt["webpack"] = OPTIONS[:front_end_lib][:variants][val[0]].downcase # First item only.
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
}

module Ask
  Interrupt = Class.new(RuntimeError)

  extend self

  def line(definition, default_value)
    default_text = default_value ? " (default: #{default_value})" : nil
    loop do
      print definition[:label], default_text, " -> "
      answer = get_string
      answer = default_value if answer.empty?
      return answer if answer

      puts "Unexpected answer!"
    end
  end

  def yes?(definition, default_value)
    default_text = default_value ? " (default: #{default_value})" : nil
    loop do
      print definition[:label], default_text, " (y/n) -> "
      answer = get_char || default_value
      puts

      case answer
      when "y" then return true
      when "n" then return false
      end

      puts "Unexpected answer!"
    end
  end

  def one_of(definition, default_value)
    default_text = default_value ? " (default: #{default_value})" : nil
    variants = definition[:variants].transform_keys(&:to_s)
    hint = variants.map { |k, v| "#{k} - #{v}" }.join("\n")

    print definition[:label], default_text, "\n", hint, "\n"

    loop do
      print "Choose one -> "
      answer = get_char || default_value
      puts

      return answer if variants.key?(answer)

      puts "Unexpected answer!"
    end
  end

  def many_of(definition, default_value)
    default_text = default_value ? " (default: #{default_value})" : nil
    variants = definition[:variants].transform_keys(&:to_s)
    hint = variants.map { |k, v| "#{k} - #{v}" }.join("\n")

    print definition[:label], default_text, "\n", hint, "\n"

    loop do
      print "Choose one or more and press Enter -> "
      answer = get_string
      answer = default_value if answer.empty?
      keys = answer.split("")

      return answer if (variants.keys & keys).size == keys.size

      puts "Unexpected answer!"
    end
  end

  private

  def get_string
    Signal.trap('INT') { raise Interrupt } # Ctrl+C
    result = gets # nil if Ctrl+D
    raise Interrupt unless result

    result.chomp
  end

  def get_char
    c = STDIN.getch
    raise Interrupt if ["\u0003", "\u0004"].include?(c) # Ctrl+C, Ctrl+D
    print c # Inserted character is hidden by default.
    ["\r", "\n"].include?(c) ? nil : c
  end
end

class CLI
  def initialize(argv)
    @option_values_from_file = read_option_values_from_file(argv[0])
    @generator_option_values = {}
    @rails_option_values = {}
  end

  def call
    OPTIONS.each do |key, definition|
      if definition.key?(:skip_if)
        next if definition[:skip_if].call(@generator_option_values, @rails_option_values)
      end

      @generator_option_values[key] =
        if @option_values_from_file.key?(key)
          if definition[:type] == :boolean
            string_to_boolean(@option_values_from_file[key])
          else
            @option_values_from_file[key]
          end
        else
          answer(definition)
        end

      @generator_option_values[key] = @generator_option_values[key].to_i if key == :rails_version

      definition[:apply]&.call(
        @generator_option_values,
        @rails_option_values,
        @generator_option_values[key]
      )
    end

    results = @generator_option_values.each_with_object("".dup) do |(key, value), acc|
      acc << "#{key}: #{value}\n"
    end

    if ENV.fetch("NO_SAVE", "0") == "0"
      puts "", "Ready to use these options:", results, ""

      if Ask.yes?({label: "Save option values into file?"}, "y")
        file_name = Ask.line({label: "File path"}, nil)
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

  def string_to_boolean(str)
    str == "true" ? true : (str == "false" ? false : raise(ArgumentError, str))
  end

  def answer(definition)
    puts

    default_value = default(definition)

    case definition[:type]
    when :text
      Ask.line(definition, default_value)
    when :boolean
      Ask.yes?(definition, default_value)
    when :one_of
      Ask.one_of(definition, default_value)
    when :many_of
      Ask.many_of(definition, default_value)
    else
      raise ArgumentError, definition[:type].to_s
    end
  end

  def default(definition)
    value = definition[:default]&.call(@generator_option_values, @rails_option_values)
    return if value.nil?

    definition[:type] == :boolean ? (value ? "y" : "n") : value
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
    Rails::Command.invoke :application, args_for_rails_new
  end

  def args_for_rails_new
    args = ["new", @generator_option_values[:app_path]]

    @rails_option_values.each do |k, v|
      next if v == false

      args << "--#{k}"
      args << v unless v == true
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
    @postinstall.run
    @postinstall.remove
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
    front_end_libs = (@generator_option_values[:front_end_lib] || "").split("")
    front_end_libs.shift # First item has been already initialized.
    return if front_end_libs.empty?

    libs = OPTIONS[:front_end_lib][:variants].slice(*front_end_libs).values.map(&:downcase)
    commands = libs.map { |lib| "system(\"bin/rails webpacker:install:#{lib}\") or exit(1)" }.join("\n  ")

    @steps << <<~TEXT
      puts "Adding front-end libraries..."
      Dir.chdir(File.dirname(__dir__)) do
        #{commands}
      end
    TEXT
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
