# frozen_string_literal: true

module NewProject
  class Configuration
    def initialize(ask, gopt, ropt, fopt)
      @ask = ask
      @gopt = gopt
      @ropt = ropt
      @fopt = fopt
    end

    def fill_values
      Options::OPTIONS.each do |key, definition|
        next if definition.key?(:skip_if) && definition[:skip_if].call(@gopt, @ropt)

        key = :db if DB_KEYS.include?(key)

        @gopt[key] = generator_option_value(key, definition)

        definition[:apply]&.call(@gopt, @ropt, @gopt[key])
      end
    end

    private

    BOOLEANS = {"true" => true, "false" => false}.freeze
    DB_KEYS = %i[db_7 db_8].freeze

    private_constant :BOOLEANS, :DB_KEYS

    def generator_option_value(key, definition)
      # Disable calling `bundle install` at the end of `rails new` process, because this process
      # tries to install gems into system directories without explicit permissions.
      return false if key == :bundle_install && Env.system_ruby?

      return convert_string_value(@fopt[key], definition[:type]) if @fopt.key?(key)

      if Env.testing?
        message = "Unable to ask question in testing mode: #{key}"
        puts message
        raise message
      else
        puts
        @ask.question(definition)
      end
    end

    def convert_string_value(value, to_type)
      case to_type
      when :boolean
        string_to_boolean(value)
      when :many_of
        string_to_array(value)
      else
        value
      end
    end

    def string_to_array(str)
      str.split(",").map(&:strip)
    end

    def string_to_boolean(str)
      BOOLEANS.fetch(str) { raise ArgumentError, str }
    end
  end
end
