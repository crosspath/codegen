# frozen_string_literal: true

require_relative "options"
require_relative "post_install_script"

module NewProject
  class CLI
    def initialize(argv)
      @option_values_from_file = read_option_values_from_file(argv[0])
      @generator_option_values = {}
      @rails_option_values = {}
      @ask = Ask.new(@generator_option_values, @rails_option_values)
    end

    def call
      Options::OPTIONS.each do |key, definition|
        if definition.key?(:skip_if)
          next if definition[:skip_if].call(@generator_option_values, @rails_option_values)
        end

        @generator_option_values[key] =
          if @option_values_from_file.key?(key)
            case definition[:type]
            when :boolean
              string_to_boolean(@option_values_from_file[key])
            when :many_of
              string_to_array(@option_values_from_file[key])
            else
              @option_values_from_file[key]
            end
          else
            puts
            @ask.question(definition)
          end

        @generator_option_values[key] = @generator_option_values[key].to_i if key == :rails_version

        definition[:apply]&.call(
          @generator_option_values,
          @rails_option_values,
          @generator_option_values[key]
        )
      end

      results =
        @generator_option_values.each_with_object("".dup) do |(key, value), acc|
          value = value.join(", ") if value.is_a?(Array)
          acc << "#{key}: #{value}\n"
        end

      if ENV.fetch("NO_SAVE", "0") == "0"
        puts "", "Ready to use these options:", results, ""

        if @ask.yes?(label: "Save option values into file?", default: ->(_, _) { "y" })
          file_name = @ask.line(label: "File path")
          File.write(file_name, results)
        end
      end
    end

    def install_railties
      @rails_version = Gem::Requirement.new("~> #{@generator_option_values[:rails_version]}")

      # Example: gem install -N --backtrace --version '~> 7' railties
      Gem.install("railties", @rails_version, document: [])
    end

    def generate_app
      railties_bin_path = Gem.bin_path("railties", "rails", @rails_version)
      railties_path = railties_bin_path.delete_suffix("/exe/rails")

      # Fix for error "uninitialized constant Bundler::SharedHelpers"
      require "bundler/setup"

      require "#{railties_path}/lib/rails/ruby_version_check"
      require "#{railties_path}/lib/rails/command"

      # First item has higher priority than the last one.
      # Rails application generator uses $LOAD_PATH for autoloading classes and modules.
      $LOAD_PATH.unshift("#{railties_path}/lib")

      # system("#{railties_bin_path} #{args_for_rails_new.join(" ")}")
      Rails::Command.invoke(:application, args_for_rails_new)
    end

    def add_postinstall_steps
      @postinstall = PostInstallScript.new(@generator_option_values, root_dir)
      @postinstall.add_steps
    end

    def any_postinstall_steps?
      @postinstall.any_steps?
    end

    def run_postinstall_script
      @postinstall.create

      if @generator_option_values[:bundle_install]
        # Remove script if it succeeds.
        @postinstall.run && @postinstall.remove
      else
        puts PostInstallScript::POSTINSTALL_MESSAGE
      end
    end

    private

    # rubocop:disable Layout/ClassStructure Keep constants in private section to show that they're
    # not intended to be used outside of this file.
    BOOLEANS = {"true" => true, "false" => false}.freeze
    # rubocop:enable Layout/ClassStructure

    def args_for_rails_new
      args = ["new", File.expand_path(@generator_option_values[:app_path], root_dir)]

      @rails_option_values.each do |k, v|
        next if v == false

        args << (v == true ? "--#{k}" : "--#{k}=#{v}")
      end

      args
    end

    def read_option_values_from_file(file_name)
      return {} if file_name.nil? || file_name.empty?

      File.readlines(file_name).to_h do |line|
        k, v = line.split(":", 2).map(&:strip)
        [k.to_sym, v]
      end
    end

    def root_dir
      File.expand_path("../..", __dir__)
    end

    def string_to_array(str)
      str.split(",").map(&:strip)
    end

    def string_to_boolean(str)
      BOOLEANS.fetch(str) { raise ArgumentError, str }
    end
  end
end
