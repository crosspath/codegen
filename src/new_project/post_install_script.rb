# frozen_string_literal: true

require_relative "../erb_eval"

module NewProject
  class PostInstallScript
    def initialize(generator_option_values)
      @generator_option_values = generator_option_values
      @app_path = File.expand_path(@generator_option_values[:app_path], __dir__)
      @steps = []
    end

    def add_steps
      add_front_end_libs
      remove_keeps
    end

    def has_steps?
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

    FILE_NAME = "bin/postinstall"

    FILE_TEMPLATE = <<~ERB
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      <%= steps.join("\n\n") %>
    ERB

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
