# frozen_string_literal: true

require_relative "erb_eval"

class PostInstallScript
  POSTINSTALL_MESSAGE =
    "You should run `bundle install` and then `bin/postinstall` within application directory " \
      "before applying any other changes to project directory."

  class Step
    def initialize(app_path)
      @app_path = app_path
    end

    def self.indent(code)
      code.split("\n").map { |x| x.empty? ? x : "  #{x}" }.join("\n").rstrip
    end

    private

    def indent(code)
      self.class.indent(code)
    end
  end

  def initialize(app_path)
    @app_path = app_path
    @code_blocks = []
  end

  def add_steps(*steps)
    @code_blocks += steps.filter_map { |step| step.new(@app_path).call }
  end

  def any_code_blocks?
    !@code_blocks.empty?
  end

  def create
    text = ErbEval.call(FILE_TEMPLATE, steps: @code_blocks)

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

  private_constant :FILE_NAME, :FILE_TEMPLATE
end
