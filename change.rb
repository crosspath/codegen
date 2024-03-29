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

    not_supported_features = @features - Feature.all.keys
    raise ArgumentError, not_supported_features.join(", ") unless not_supported_features.empty?
  end

  def call
    @app_path = @ask.line(label: "Application path") if @app_path.nil? || @app_path.empty?
    @app_path = File.expand_path(@app_path, __dir__)

    if @features.empty?
      Feature.all.each_key do |key|
        @features << key if @ask.yes?(label: "Use #{key}", default: ->(_, _) { "y" })
      end
    end

    # Sort by `Feature.all`.
    (Feature.all.keys & @features).each do |feature_name|
      puts "", "Using #{feature_name}..."
      Feature.all[feature_name].new(self).call
    end

    puts "Done!"
  end
end

CLI.new(ARGV.dup).call
