# frozen_string_literal: true

require_relative "../erb_eval"

module NewProject
  class PostInstallScript
    POSTINSTALL_MESSAGE =
      "You should run `bundle install` and then `bin/postinstall` within application directory."

    def initialize(generator_option_values)
      @generator_option_values = generator_option_values
      @app_path = File.expand_path(@generator_option_values[:app_path], Dir.pwd)
      @steps = []
    end

    def add_steps
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

    FILE_NAME = "bin/postinstall"

    FILE_TEMPLATE = <<~ERB.freeze
      #!/usr/bin/env ruby
      # frozen_string_literal: true

      Dir.chdir(File.dirname(__dir__)) do
        <%= steps.join("\n\n") %>
      end

      puts "Now you may delete file #{FILE_NAME}"
    ERB

    STEP_KEEPS = <<~RUBY
      puts "Remove vendor/javascript/.keep..."
      File.unlink("vendor/javascript/.keep") if File.exist?("vendor/javascript/.keep")
      if Dir.empty?("vendor/javascript")
        Dir.delete("vendor/javascript")
        if File.exist?("app/assets/config/manifest.js")
          lines = File.readlines("app/assets/config/manifest.js")
          lines -= ["//= link_tree ../../../vendor/javascript .js\\n"]
          File.write("app/assets/config/manifest.js", lines.join)
        end
      end
    RUBY

    private_constant :FILE_NAME, :FILE_TEMPLATE, :STEP_KEEPS

    def remove_keeps
      return if @generator_option_values[:keeps]

      keep_file_path = File.join(@app_path, "vendor/javascript/.keep")
      return unless File.exist?(keep_file_path)

      @steps << indent(STEP_KEEPS)
    end

    def indent(code)
      "  #{code.split("\n").join("\n  ")}"
    end
  end
end
