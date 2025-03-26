# frozen_string_literal: true

require_relative "../env"
require_relative "../string_utils"
require_relative "gem_template"
require_relative "options"

module NewGem
  class CLI
    def initialize(argv)
      @cli_options = %i[gem_path name].zip(argv).to_h
      @generator_option_values = {}
      @ask = Ask.new(@generator_option_values, nil)
    end

    def call
      Options::OPTIONS.each do |key, definition|
        next if definition.key?(:skip_if) && definition[:skip_if].call(@generator_option_values)

        @generator_option_values[key] =
          @cli_options.fetch(key) { generator_option_value(key, definition) }

        definition[:apply]&.call(@generator_option_values, @generator_option_values[key])
      end

      # return if Env.testing?
    end

    def create_files
      # Given: "3.3.6". Result: "3.3".
      ruby_version = RUBY_VERSION.split(".", 3)[0..1].join(".")

      GemTemplate.new(gem_base_file_name:, gem_class_name:, gem_path:, ruby_version:).generate
    end

    private

    def gem_class_name
      @gem_class_name ||=
        begin
          name = @generator_option_values[:name]
          StringUtils.with_capitalize?(name) ? name : StringUtils.underscores_to_capitalize(name)
        end
    end

    def gem_base_file_name
      @gem_base_file_name ||=
        begin
          name = @generator_option_values[:name]
          StringUtils.with_capitalize?(name) ? StringUtils.capitalize_to_underscores(name) : name
        end
    end

    # @return [String]
    def gem_path
      @gem_path ||= File.expand_path(@generator_option_values[:gem_path], Dir.pwd)
    end

    # @param key [Symbol]
    # @param definition [Hash<Symbol, Object>]
    # @raise RuntimeError
    # @return [String, Boolean, Array<String>]
    def generator_option_value(key, definition)
      if Env.testing?
        message = "Unable to ask question in testing mode: #{key}"
        puts message
        raise message
      else
        puts
        @ask.question(definition)
      end
    end
  end
end
