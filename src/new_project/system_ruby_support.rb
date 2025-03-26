# frozen_string_literal: true

module NewProject
  # Additional actions for granting user permissions to gem directories.
  module SystemRubySupport
    extend self

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

    def change_permissions_for_block
      paths = GEM_PATHS.join(" ")
      rubygems_uses_flock = Gem::Version.new(Gem::VERSION) > Gem::Version.new("3.5.14")

      begin
        grant_permissions(paths, rubygems_uses_flock)
        yield
      ensure
        remove_rails_lock_file if rubygems_uses_flock
        deny_access_to_gem_dirs(paths)
      end
    end

    private

    def allow_access_to_gem_dirs(paths)
      user = Env.user

      system("sudo chmod 0777 /usr/bin /usr/local/bin")
      system("sudo chown #{user}:#{user} #{paths}")
    end

    def create_rails_lock_file
      system("sudo touch /usr/bin/rails.lock && sudo chmod 0777 /usr/bin/rails.lock")
    end

    def deny_access_to_gem_dirs(paths)
      system("sudo chown root:root #{paths}")
      system("sudo chmod 0755 /usr/bin /usr/local/bin")
    end

    def grant_permissions(paths, flock)
      puts "Your Ruby installation requires sudo privileges for installing gems."

      allow_access_to_gem_dirs(paths)
      create_rails_lock_file if flock
    end

    def remove_rails_lock_file
      system("sudo rm -f /usr/bin/rails.lock")
    end
  end
end
