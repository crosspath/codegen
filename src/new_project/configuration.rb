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

        @gopt[key] = generator_option_value(key, definition)

        definition[:apply]&.call(@gopt, @ropt, @gopt[key])
      end
    end

    private

    BOOLEANS = {"true" => true, "false" => false}.freeze
    private_constant :BOOLEANS

    def generator_option_value(key, definition)
      res =
        if key == :bundle_install && Env.system_ruby?
          # Disable calling `bundle install` at the end of `rails new` process, because this process
          # tries to install gems into system directories without explicit permissions.
          false
        elsif @fopt.key?(key)
          convert_string_value(@fopt[key], definition[:type])
        else
          puts
          @ask.question(definition)
        end

      key == :rails_version ? res.to_i : res
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
