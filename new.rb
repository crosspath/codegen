#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./new.rb
# ./new.rb file-name-with-options

require "io/console"
require "railties"

# OptionName ::= String
# OptionValue ::= String | true | false
# OptionDefinition ::= Hash {
#   label: String,
#   type: :text | :boolean | :one_of | :many_of,
#   variants: Hash(String, String), # if type == :one_of || type == :many_of
#   default: Proc(Hash(OptionName, OptionValue)) -> OptionValue, # optional
#   apply: Proc(Hash(OptionName, OptionValue), OptionValue),
#   skip_if: Proc(Hash(OptionName, OptionValue)) -> true | false # optional
# }
# typeof OPTIONS == Hash(Symbol, OptionDefinition)
#
# OptionName:
# - down_case if Rails generator knows this name;
# - starts with "." otherwise.
OPTIONS = {
  rails_version: {
    label: "Rails version",
    type: :one_of,
    variants: {
      "6" => "Rails 6",
      "7" => "Rails 7",
    },
    default: ->(_) { "7" },
    apply: ->(opt, val) { opt[".rails_version"] = val.to_i },
  },
  app_path: {
    label: "Application path",
    type: :text,
    apply: ->(opt, val) { opt[".app_path"] = val },
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
    default: ->(_) { "1" },
    apply: ->(opt, val) do
      case val
      when "1" then next
      when "2" then opt["minimal"] = true
      when "3" then opt["api"] = true
      end
    end,
  },
  active_record: {
    label: "Add Active Record - Rails ORM",
    type: :boolean,
    default: ->(opt) { true },
    apply: ->(opt, val) { opt["skip-action-record"] = !val },
    skip_if: ->(opt) { opt["minimal"] },
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
    default: ->(_) { "2" },
    apply: ->(opt, val) do
      opt["database"] =
        val == "0" ? Ask.line("Gem name for database") : OPTIONS[:db][:variants][val]
    end,
    skip_if: ->(opt) { opt["skip-action-record"] },
  },
  js: {
    label: "Add JavaScript",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) { opt["skip-javascript"] = !val },
    skip_if: ->(opt) { opt["api"] },
  },
  dev_gems: {
    label: "Add gems for development - web-console, rack-mini-profiler",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) { opt["skip-dev-gems"] = !val },
    skip_if: ->(opt) { opt["api"] },
  },
  keeps: {
    label: "Files .keep in directories: */concerns, lib/tasks, log, tmp",
    type: :boolean,
    default: ->(opt) { false },
    apply: ->(opt, val) { opt["skip-keeps"] = !val },
  },
  mailer: {
    label: "Add Action Mailer - send emails",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-action-mailer"] = true if val
      else
        opt["skip-action-mailer"] = true unless val
      end
    end,
  },
  mailbox: {
    label: "Add Action Mailbox - receive emails",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-action-mailbox"] = true if val
      else
        opt["skip-action-mailbox"] = true unless val
      end
    end,
  },
  action_text: {
    label: "Add Action Text - embedded HTML editor",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-action-text"] = true if val
      else
        opt["skip-action-text"] = true unless val
      end
    end,
    skip_if: ->(opt) { opt["api"] || opt["skip-javascript"] },
  },
  active_job: {
    label: "Add Active Job - queue manager",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-active-job"] = true if val
      else
        opt["skip-active-job"] = true unless val
      end
    end,
  },
  active_storage: {
    label: "Add Active Storage - file uploader",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-active-storage"] = true if val
      else
        opt["skip-active-storage"] = true unless val
      end
    end,
  },
  action_cable: {
    label: "Add Action Cable - WebSockets support",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-active-cable"] = true if val
      else
        opt["skip-active-cable"] = true unless val
      end
    end,
  },
  assets: {
    label: "Add asset pipeline",
    type: :boolean,
    default: ->(opt) { true },
    apply: ->(opt, val) do
      if opt[".rails_version"] < 7
        opt["skip-sprockets"] = !val
      else
        opt["skip-asset-pipeline"] = !val
      end
    end,
    skip_if: ->(opt) { opt["api"] },
  },
  assets_lib: {
    label: "Library for asset pipeline",
    type: :one_of,
    variants: {
      "1" => "Sprockets",
      "2" => "Propshaft",
    },
    default: ->(_) { "1" },
    apply: ->(opt, val) { opt["asset-pipeline"] = OPTIONS[:assets_lib][:variants][val].downcase },
    skip_if: ->(opt) { opt["api"] || opt[".rails_version"] < 7 || opt["skip-asset-pipeline"] },
  },
  hotwire: {
    label: "Add Hotwire",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-hotwire"] = true if val
      else
        opt["skip-hotwire"] = true unless val
      end
    end,
    skip_if: ->(opt) { opt[".rails_version"] < 7 || opt["api"] || opt["skip-javascript"] },
  },
  turbolinks: {
    label: "Add Turbolinks",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-turbolinks"] = true if val
      else
        opt["skip-turbolinks"] = true unless val
      end
    end,
    skip_if: ->(opt) { opt[".rails_version"] >= 7 || opt["api"] || opt["skip-javascript"] },
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
    default: ->(_) { "i" },
    apply: ->(opt, val) { opt["javascript"] = OPTIONS[:js_bundler][:variants][val].downcase },
    skip_if: ->(opt) { opt[".rails_version"] < 7 || opt["api"] || opt["skip-javascript"] },
  },
  css_lib: {
    label: "Library for CSS",
    type: :one_of,
    variants: {
      "b" => "Bootstrap",
      "p" => "PostCSS",
      "s" => "Sass",
      "t" => "Tailwind",
      "u" => "Bulma", # https://bulma.io/documentation/overview/
    },
    default: ->(_) { "u" },
    apply: ->(opt, val) { opt["css"] = OPTIONS[:css_lib][:variants][val].downcase },
    skip_if: ->(opt) { opt[".rails_version"] < 7 || opt["api"] },
  },
  webpacker: {
    label: "Add Webpacker",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      opt[".webpacker"] = val
      if opt["minimal"]
        opt["no-skip-webpack-install"] = true if val
      else
        opt["skip-webpack-install"] = true unless val
      end
    end,
    skip_if: ->(opt) { opt[".rails_version"] >= 7 || opt["api"] || opt["skip-javascript"] },
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
    default: ->(_) { "e" },
    apply: ->(opt, val) do
      opt["webpack"] = OPTIONS[:front_end_lib][:variants][val.shift].downcase # First item.
      opt[".webpack"] = val unless val.empty? # All the rest items.
    end,
    skip_if: ->(opt) { opt[".rails_version"] >= 7 || opt["api"] || opt["skip-javascript"] || !opt[".webpacker"] },
  },
  spring: {
    label: "Add Spring",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-spring"] = true if val
      else
        opt["skip-spring"] = true unless val
      end
    end,
    skip_if: ->(opt) { opt[".rails_version"] >= 7 },
  },
  jbuilder: {
    label: "Add jbuilder",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-jbuilder"] = true if val
      else
        opt["skip-jbuilder"] = true unless val
      end
    end,
  },
  bootsnap: {
    label: "Add Bootsnap",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-bootsnap"] = true if val
      else
        opt["skip-bootsnap"] = true unless val
      end
    end,
  },
  tests: {
    label: "Add tests - Minitest",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      opt[".tests"] = val
      if opt["minimal"]
        opt["no-skip-test"] = true if val
      else
        opt["skip-test"] = true unless val
      end
    end,
  },
  system_tests: {
    label: "Add system tests - Capybara, Selenium",
    type: :boolean,
    default: ->(opt) { !opt["minimal"] },
    apply: ->(opt, val) do
      if opt["minimal"]
        opt["no-skip-system-test"] = true if val
      else
        opt["skip-system-test"] = true unless val
      end
    end,
    skip_if: ->(opt) { opt["api"] || !opt[".tests"] },
  },
  bundle_install: {
    label: "Run `bundle install` at the end of this process",
    type: :boolean,
    default: ->(opt) { true },
    apply: ->(opt, val) { opt["skip-bundle"] = !val },
  },
  # listen: {
  #   label: "Add `listen` gem",
  #   type: :boolean,
  #   default: ->(opt) { true },
  #   apply: ->(opt, val) { opt["skip-listen"] = !val },
  # },
  # puma: {
  #   label: "Add Puma",
  #   type: :boolean,
  #   default: ->(opt) { true },
  #   apply: ->(opt, val) { opt["skip-puma"] = !val },
  # },
  # git: {
  #   label: "Create .gitignore",
  #   type: :boolean,
  #   default: ->(opt) { true },
  #   apply: ->(opt, val) { opt["skip-git"] = !val },
  # },
  # gemfile: {
  #   label: "Add Gemfile",
  #   type: :boolean,
  #   default: ->(opt) { true },
  #   apply: ->(opt, val) { opt["skip-gemfile"] = !val },
  # },
}

module Ask
  Interrupt = Class.new(RuntimeError)

  extend self

  def line(definition)
    loop do
      default = definition[:default]
      print definition[:label], (default ? " (default: #{default})" : ""), " -> "
      answer = get_string
      answer = default if answer.empty?
      return answer if answer

      puts "Unexpected answer!"
    end
  end

  def yes?(definition)
    loop do
      default = definition.key?(:default) ? (definition[:default] ? "y" : "n") : nil
      print definition[:label], (default ? " (default: #{default})" : ""), " (y/n) -> "
      answer = get_char || default
      puts

      case answer
      when "y" then return true
      when "n" then return false
      end

      puts "Unexpected answer!"
    end
  end

  def one_of(definition)
    default = definition[:default]
    variants = definition[:variants].transform_keys(&:to_s)
    hint = variants.map { |k, v| "#{k} - #{v}" }.join("\n")

    print definition[:label], (default ? " (default: #{default})" : ""), "\n", hint, "\n"

    loop do
      print "Choose one -> "
      answer = get_char || default
      puts

      return answer if variants.key?(answer)

      puts "Unexpected answer!"
    end
  end

  def many_of(definition)
    default = definition[:default]
    variants = definition[:variants].transform_keys(&:to_s)
    hint = variants.map { |k, v| "#{k} - #{v}" }.join("\n")

    print definition[:label], (default ? " (default: #{default})" : ""), "\n", hint, "\n"

    loop do
      print "Choose one or more -> "
      answer = get_string
      answer = default if answer.empty?
      keys = answer.split("")

      return keys if (variants.keys & keys).size == keys.size

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

module CLI
  extend self

  def read_option_values_from_file(file_name)
    file_name ? File.readlines(file_name).to_h { |line| line.strip.split(":", 2) } : {}
  end
end

option_values_from_file = CLI.read_option_values_from_file(ARGV[0])
option_values = {}

OPTIONS.each do |key, definition|
  next if definition.key?(:skip_if) && definition[:skip_if].call(option_values)

  if option_values_from_file.key?(key)
    option_values[key] = option_values_from_file[key]
    next
  end

  value =
    case definition[:type]
    when :text
      Ask.line(definition)
    when :boolean
      Ask.yes?(definition)
    when :one_of
      Ask.one_of(definition)
    when :many_of
      Ask.many_of(definition)
    else
      raise ArgumentError, definition[:type].to_s
    end

  definition[:apply].call(option_values, value)
end

# Debug
puts "Ready to use these options:"

option_values.each do |key, value|
  puts "#{key}: #{value}"
end
