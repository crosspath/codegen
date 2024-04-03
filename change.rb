#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./change.rb
# ./change.rb project-directory
# ./change.rb project-directory feature-name
# ./change.rb project-directory feature-1 feature-2 feature-3 ...

require_relative "src/ask"
require_relative "src/feature"

Dir["#{__dir__}/features/*/*.rb"].sort.each { |f| require_relative(f) }

class CLI
  attr_reader :app_path, :ask

  def initialize(argv)
    @app_path = argv.shift
    @features = argv
    @ask = Ask.new({}, {})
    @known_features = FeatureRegistry.all

    not_supported_features = @features - @known_features.keys
    raise ArgumentError, not_supported_features.join(", ") unless not_supported_features.empty?
  end

  def call
    @app_path = @ask.line(label: "Application path") if @app_path.nil? || @app_path.empty?
    @app_path = File.expand_path(@app_path, __dir__)

    if @features.empty?
      @known_features.each_key do |key|
        @features << key if @ask.yes?(label: "Use #{key}", default: ->(_, _) { "y" })
      end
    end

    # Sort by `FeatureRegistry.all`.
    (@known_features.keys & @features).each do |feature_key|
      puts "", "Using #{@known_features[feature_key].name}..."
      @known_features[feature_key].klass.new(self).call
    end

    puts "Done!"
  end
end

CLI.new(ARGV.dup).call
