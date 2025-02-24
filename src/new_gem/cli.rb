# frozen_string_literal: true

require_relative "../env"
require_relative "../erb_eval"
require_relative "../string_utils"
require_relative "options"

module NewGem
  class CLI
    def initialize(_argv)
      @generator_option_values = {}
      @ask = Ask.new(@generator_option_values, nil)
    end

    def call
      Options::OPTIONS.each do |key, definition|
        next if definition.key?(:skip_if) && definition[:skip_if].call(@generator_option_values)

        @generator_option_values[key] = generator_option_value(key, definition)

        definition[:apply]&.call(@generator_option_values, @generator_option_values[key])
      end

      # return if Env.testing?
    end

    def create_files
      # Given: "3.3.6". Result: "3.3".
      ruby_version = RUBY_VERSION.split(".", 3)[0..1].join(".")

      create_gem_dir("bin")
      create_gem_dir("exe")
      create_gem_dir("lib/#{gem_base_file_name}")

      copy_files_to_gem(".bundle", "")
      copy_files_to_gem(".gitignore", "")
      copy_files_to_gem("CHANGELOG.md", "")
      copy_files_to_gem("Gemfile", "")
      copy_files_to_gem("bin/rubocop", "bin")
      copy_files_to_gem("bin/yard", "bin")

      erb(".rubocop.yml", ".rubocop.yml", ruby_version:)

      erb(
        "gem.gemspec",
        "#{gem_base_file_name}.gemspec",
        gem_author: `git config get --global user.name`.strip,
        gem_base_file_name:,
        gem_class_name:,
        ruby_version: "#{ruby_version}.0"
      )

      erb(
        "README.md",
        "README.md",
        name: StringUtils.underscores_to_titleize(gem_base_file_name)
      )

      erb("bin/build", "bin/build", gem_base_file_name:, gem_class_name:)
      erb("bin/release", "bin/release", gem_base_file_name:, gem_class_name:)
      erb("exe/gem", "exe/#{gem_base_file_name}", gem_base_file_name:, gem_class_name:)
      erb("lib/gem.rb", "lib/#{gem_base_file_name}.rb", gem_base_file_name:, gem_class_name:)
      erb("lib/gem/version.rb", "lib/#{gem_base_file_name}/version.rb", gem_class_name:)

      `chmod +x #{gem_path}/exe/#{gem_base_file_name} #{gem_path}/bin/*`
    end

    private

    # Copy files or directories.
    # @param read_from [String]
    # @param save_to [String]
    # @return [String] Command output
    def copy_files_to_gem(read_from, save_to)
      source = File.join(__dir__, "files", read_from)
      destination = File.join(gem_path, save_to)

      `cp -r #{source} #{destination}`
    end

    # @param dir_name [String]
    # @return [Boolean] Operation state ("true" on success)
    def create_gem_dir(dir_name)
      `mkdir -m 0755 -p #{gem_path}/#{dir_name}`
    end

    # @param read_from [String]
    # @param save_to [String]
    # @param locals [Hash<String, Object>]
    # @return [void]
    def erb(read_from, save_to, **locals)
      file_name = File.join(__dir__, "files", "#{read_from}.erb")
      result = ErbEval.call(File.read(file_name), **locals)
      result += "\n" unless result.end_with?("\n")

      File.write(File.join(gem_path, save_to), result)
    end

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
