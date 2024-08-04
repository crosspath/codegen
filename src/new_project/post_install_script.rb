# frozen_string_literal: true

require_relative "../erb_eval"

module NewProject
  class PostInstallScript
    POSTINSTALL_MESSAGE =
      "You should run `bundle install` and then `bin/postinstall` within application directory."

    def initialize(generator_option_values, root_dir)
      @generator_option_values = generator_option_values
      @app_path = File.expand_path(@generator_option_values[:app_path], root_dir)
      @steps = []
    end

    def add_steps
      add_core_gems_for_ruby_3_3 if Gem.ruby_version >= Gem::Version.new("3.3.0")
      add_front_end_libs
      remove_keeps
    end

    def any_steps?
      !@steps.empty?
    end

    def create
      text = ErbEval.call(FILE_TEMPLATE, steps: @steps)

      Dir.chdir(@app_path) do
        File.write(FILE_NAME, text)
        File.chmod(0o755, FILE_NAME) # rwxr-xr-x
      end
    end

    def run
      Dir.chdir(@app_path) { system(FILE_NAME) }
    end

    def remove
      Dir.chdir(@app_path) { File.unlink(FILE_NAME) }
    end

    private

    # rubocop:disable Layout/ClassStructure Keep constants in private section to show that they're
    # not intended to be used outside of this file.
    FILE_NAME = "bin/postinstall"

    FILE_TEMPLATE = <<~ERB
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      <%= steps.join("\n\n") %>
    ERB

    STEP_CORE_GEMS = <<~RUBY
      puts "Add core gems for Ruby 3.3 to Gemfile..."
      Dir.chdir(File.dirname(__dir__)) do
        File.open("Gemfile", "a") { |f| f << %(\ngem "base64"\ngem "bigdecimal"\ngem "mutex_m"\n) }
      end
    RUBY

    STEP_WEBPACKER = <<~ERB
      puts "Adding front-end libraries..."
      Dir.chdir(File.dirname(__dir__)) do
        <% libs.each do |lib| %>
        system("bin/rails webpacker:install:<%= lib %>") or exit(1)
        <% end %>
      end
    ERB

    STEP_KEEPS = <<~RUBY
      puts "Remove vendor/javascript/.keep..."
      Dir.chdir(File.dirname(__dir__)) do
        File.unlink("vendor/javascript/.keep") if File.exist?("vendor/javascript/.keep")
        if Dir.empty?("vendor/javascript")
          Dir.delete("vendor/javascript")
          if File.exist?("app/assets/config/manifest.js")
            lines = File.readlines("app/assets/config/manifest.js")
            lines -= ["//= link_tree ../../../vendor/javascript .js\\n"]
            File.write("app/assets/config/manifest.js", lines.join)
          end
        end
      end
    RUBY
    # rubocop:enable Layout/ClassStructure

    # Fix for warnings:
    #   active_support/message_encryptor.rb:4: warning: base64 was loaded from the standard library,
    #   but will no longer be part of the default gems since Ruby 3.4.0. Add base64 to your Gemfile
    #   or gemspec. Also contact author of activesupport-7.1.3.4 to add base64 into its gemspec.
    #
    #   active_support/core_ext/object/json.rb:5: warning: bigdecimal was loaded from the standard
    #   library, but will no longer be part of the default gems since Ruby 3.4.0. Add bigdecimal to
    #   your Gemfile or gemspec. Also contact author of activesupport-7.1.3.4 to add bigdecimal into
    #   its gemspec.
    #
    #   active_support/notifications/fanout.rb:3: warning: mutex_m was loaded from the standard
    #   library, but will no longer be part of the default gems since Ruby 3.4.0. Add mutex_m to
    #   your Gemfile or gemspec. Also contact author of activesupport-7.1.3.4 to add mutex_m into
    #   its gemspec.
    def add_core_gems_for_ruby_3_3
      @steps << STEP_CORE_GEMS
    end

    def add_front_end_libs
      front_end_libs = @generator_option_values[:front_end_lib] || []
      front_end_libs.shift # First item has been already initialized.
      return if front_end_libs.empty?

      @steps << ErbEval.call(STEP_WEBPACKER, libs: front_end_libs)
    end

    def remove_keeps
      return if @generator_option_values[:keeps]

      keep_file_path = File.join(@app_path, "vendor/javascript/.keep")
      return unless File.exist?(keep_file_path)

      @steps << STEP_KEEPS
    end
  end
end
