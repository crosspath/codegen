# frozen_string_literal: true

require_relative "../ask"
require_relative "../feature"

module ChangeProject
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
      root_dir = File.expand_path("../..", __dir__)

      @app_path = @ask.line(label: "Application path") if @app_path.nil? || @app_path.empty?
      @app_path = File.expand_path(@app_path, root_dir)

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
end
