# frozen_string_literal: true

require_relative "../env"
require_relative "../gem_version"
require_relative "../post_install_script"
require_relative "../post_install_steps/add_default_gems"
require_relative "../post_install_steps/remove_keeps"
require_relative "../string_utils"
require_relative "config_file"
require_relative "configuration"
require_relative "options"

module NewProject
  class CLI
    BASE_RUBY_VERSION = RUBY_VERSION.split(".").then { |x| (x[-1] = 0) && x }.join(".").freeze
    GEM_HOME = Gem.paths.home.freeze

    GEM_PATHS = [
      GEM_HOME,
      "#{GEM_HOME}/bundler/gems",
      "#{GEM_HOME}/cache",
      *Dir["#{GEM_HOME}/extensions/*/#{BASE_RUBY_VERSION}"],
      "#{GEM_HOME}/gems",
      "#{GEM_HOME}/plugins",
      "#{GEM_HOME}/specifications",
    ].freeze

    def initialize(argv)
      @generator_option_values = {}

      # Uncomment line below after dropping support for Rails 7.
      # @generator_option_values[:rails_version] = "8" # Minimal supported version.

      @rails_option_values = {}
      @ask = Ask.new(@generator_option_values, @rails_option_values)
      @configuration = init_configuration(argv[0])
    end

    def call
      @configuration.fill_values
      return if Env.testing?

      results = ConfigFile.generate(@generator_option_values)

      puts "", "Ready to use these options:", results, ""

      return unless save_options?

      file_name = @ask.question(type: :text, label: "File path")
      File.write(file_name, results)
    end

    # Fix for "system" version of Ruby. It's installed with root permissions, therefore we have to
    # change permissions for gem directories temporarily.
    def ensure_gem_path_is_writable
      return yield unless Env.system_ruby?

      paths = GEM_PATHS.join(" ")
      rubygems_uses_flock = Gem::Version.new(Gem::VERSION) > Gem::Version.new("3.5.14")

      begin
        puts "Your Ruby installation requires sudo privileges for installing gems."

        allow_access_to_gem_dirs(paths)
        create_rails_lock_file if rubygems_uses_flock

        yield
      ensure
        remove_rails_lock_file if rubygems_uses_flock
        deny_access_to_gem_dirs(paths)
      end
    end

    def railties_installed?
      @rails_version = Gem::Requirement.new("~> #{@generator_option_values[:rails_version]}")

      # Latest version of "railties" gem for specified release.
      latest_version = GemVersion.latest("railties", @rails_version)

      Gem::Specification.any? { |s| s.name == "railties" && s.version == latest_version }
    end

    def install_railties
      # Example: gem install -N --backtrace --version '~> 7' railties
      Gem.install("railties", @rails_version, document: [])
    end

    def generate_app
      railties_bin_path = Gem.bin_path("railties", "rails", @rails_version)
      railties_path = railties_bin_path.delete_suffix("/exe/rails")

      # Fix for error "uninitialized constant Bundler::SharedHelpers"
      require "bundler/shared_helpers"

      add_items_to_load_path(railties_path)
      load_rails_files(railties_path)

      Rails::Command.invoke(:application, args_for_rails_new)
    end

    def add_postinstall_steps
      @postinstall = PostInstallScript.new(app_path)
      @postinstall.add_steps(PostInstallSteps::AddDefaultGems)
      @postinstall.add_steps(PostInstallSteps::RemoveKeeps) if @generator_option_values[:keeps]
    end

    def any_postinstall_steps?
      @postinstall.any_code_blocks?
    end

    def run_postinstall_script
      @postinstall.create

      if @generator_option_values[:bundle_install]
        # Remove script if it succeeds.
        @postinstall.run && @postinstall.remove
      else
        StringUtils.warning(PostInstallScript::POSTINSTALL_MESSAGE)
      end
    end

    private

    # @return [String]
    def app_path
      @app_path ||= File.expand_path(@generator_option_values[:app_path], Dir.pwd)
    end

    def args_for_rails_new
      args = ["new", app_path]

      @rails_option_values.each do |k, v|
        next if v == false

        args << (v == true ? "--#{k}" : "--#{k}=#{v}")
      end

      args
    end

    def init_configuration(file_path)
      option_values = ConfigFile.read_options_from_file(file_path)

      Configuration.new(@ask, @generator_option_values, @rails_option_values, option_values)
    end

    def save_options?
      @ask.question(
        type: :boolean,
        label: "Save option values into file?",
        default: ->(_, _) { "y" }
      )
    end

    def allow_access_to_gem_dirs(paths)
      user = Env.user

      system("sudo chmod 0777 /usr/bin /usr/local/bin")
      system("sudo chown #{user}:#{user} #{paths}")
    end

    def deny_access_to_gem_dirs(paths)
      system("sudo chown root:root #{paths}")
      system("sudo chmod 0755 /usr/bin /usr/local/bin")
    end

    def add_items_to_load_path(railties_path)
      # Fixes for "(LoadError) cannot load such file".
      # First item has higher priority than the last one.
      # Rails application generator uses $LOAD_PATH for autoloading classes and modules.
      $LOAD_PATH.unshift("#{railties_path.sub("railties", "activesupport")}/lib")
      $LOAD_PATH.unshift("#{latest_installed_gem_version("concurrent-ruby")}/lib/concurrent-ruby")
      $LOAD_PATH.unshift("#{latest_installed_gem_version("i18n")}/lib")
      $LOAD_PATH.unshift("#{latest_installed_gem_version("thor")}/lib")
      $LOAD_PATH.unshift("#{latest_installed_gem_version("tzinfo")}/lib")
      $LOAD_PATH.unshift("#{railties_path}/lib")
    end

    def latest_installed_gem_version(gem_name)
      Dir["#{GEM_HOME}/gems/#{gem_name}-*", sort: true].last
    end

    def load_rails_files(railties_path)
      require "#{railties_path}/lib/rails/command"
    end

    def create_rails_lock_file
      system("sudo touch /usr/bin/rails.lock && sudo chmod 0777 /usr/bin/rails.lock")
    end

    def remove_rails_lock_file
      system("sudo rm -f /usr/bin/rails.lock")
    end
  end
end
