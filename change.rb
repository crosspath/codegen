#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./change.rb
# ./change.rb project-directory
# ./change.rb project-directory feature-name
# ./change.rb project-directory feature-1 feature-2 feature-3 ...

require "erubi"
require "io/console"
require_relative "src/ask"
require_relative "src/feature"

Dir["features/*/*.rb"].sort.each { |f| require(f) }

class CLI
  attr_reader :app_path, :ask

  def initialize(argv)
    @app_path = argv.shift
    @features = argv
    @ask = Ask.new({}, {})

    not_supported_features = @features - Feature.all.keys
    raise ArgumentError, not_supported_features.join(", ") unless not_supported_features.empty?
  end

  def call
    @app_path = @ask.line(label: "Application path") if @app_path.nil? || @app_path.empty?
    @app_path = File.expand_path(@app_path, __dir__)

    @features.each do |feature_name|
      puts "Running #{feature_name}..."
      Feature.all[feature_name].new(self).call
    end
  end
end

CLI.new(ARGV.dup).call
