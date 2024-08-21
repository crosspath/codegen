# frozen_string_literal: true

require_relative "../ask"
require_relative "../env"
require_relative "../feature"
require_relative "../hash"

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
      normalize_app_path
      select_features if @features.empty?
      apply_selected_features

      puts "Done!"
    end

    private

    def normalize_app_path
      if @app_path.nil? || @app_path.empty?
        @app_path = @ask.question(type: :text, label: "Application path")
      end

      @app_path = File.expand_path(@app_path, Env.root_dir)
    end

    def select_features
      default_answer = ->(_, _) { "y" }

      @known_features.each_key do |key|
        next unless @ask.question(type: :boolean, label: "Use #{key}", default: default_answer)

        @features << key
      end
    end

    def apply_selected_features
      # Sort by `FeatureRegistry.all`.
      (@known_features.keys & @features).each do |feature_key|
        puts "", "Using #{@known_features[feature_key].name}..."
        @known_features[feature_key].klass.new(self).call
      end
    end
  end
end
