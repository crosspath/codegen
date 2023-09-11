#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./new.rb
# ./new.rb file-name-with-options

require "io/console"

# OptionName ::= String
# OptionValue ::= String | true | false
# OptionDefinition ::= Hash {
#   label: String,
#   type: :text | :boolean | :variants,
#   variants: Hash(String, String), # if type == :variants
#   default: OptionValue, # optional
#   apply: Proc(Hash(OptionName, OptionValue), OptionValue),
#   skip_if: Proc(Hash(OptionName, OptionValue)) -> true | false # optional
# }
# typeof OPTIONS == Hash(Symbol, OptionDefinition)
#
# OptionName:
# - down_case if Rails generator knows this name;
# - starts with "." otherwise.
OPTIONS = {
  app_path: {
    label: "Application path",
    type: :text,
    apply: ->(opt, val) { opt[".app_path"] = val }
  },
  db: {
    label: "Database",
    type: :variants,
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
      "0" => "... other" # Required: gem name.
    },
    default: "postgresql",
    apply: ->(opt, val) do
      opt["database"] =
        val == "0" ? Ask.line("Gem name for database") : OPTIONS[:db][:variants][val]
    end
  },
  mode: {
    label: "Application template",
    type: :variants,
    variants: {
      "1" => "Full Stack (Ruby on Rails + front-end + mailers + etc)",
      "2" => "Minimal (Ruby on Rails + front-end)",
      "3" => "API-only (no app/assets, app/helpers)"
    },
    apply: ->(opt, val) do
      case val
      when "1" then next
      when "2" then opt["minimal"] = true
      when "3" then opt["api"] = true
      end
    end
  },
  keeps: {
    label: "Files .keep in directories: */concerns, lib/tasks, log, tmp",
    type: :boolean,
    default: false,
    apply: ->(opt, val) { opt["skip-keeps"] = !val }
  }
}

DEFAULT_OPTIONS = {
  "skip-keeps": true,
  "skip-action-mailer": false,
  "skip-action-mailbox": false,
  "skip-action-text": false,
  "skip-active-record": false,
  "skip-active-job": false,
  "skip-active-storage": false,
  "skip-action-cable": false,
  "skip-asset-pipeline": true,
  # sprockets/propshaft
  "asset-pipeline": "sprockets",
  "skip-hotwire": true,
  "skip-jbuilder": true,
  "skip-test": true,
  "skip-system-test": true,
  "skip-bootsnap": false,
  api: false,
  minimal: false,
  # importmap/webpack/esbuild/rollup
  javascript: "importmap",
  # tailwind/bootstrap/bulma/postcss/sass
  css: "bulma", # https://bulma.io/documentation/overview/
  "skip-bundle": true,
  # Custom options, not passed to `rails new`:
  path_to_rails: "rails",
}.freeze

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
      print "-> "
      answer = get_char || default
      puts

      return answer if variants.key?(answer)

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
    when :variants
      Ask.one_of(definition)
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
