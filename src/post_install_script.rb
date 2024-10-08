# frozen_string_literal: true

require_relative "erb_eval"

# Collect actions from multiple features & subfeatures for applying changes after running
# "bundle install".
class PostInstallScript
  POSTINSTALL_MESSAGE = [
    "You should run `bundle install` and then `bin/postinstall` within",
    "project directory before applying any other changes to that directory.",
  ].freeze

  # Base class for declaring actions after running "bundle install".
  # @abstract
  class Step
    # @param code [String]
    # @return [String]
    def self.indent(code)
      StringUtils.indent(code.split("\n")).join("\n").rstrip
    end

    # @param app_path [String]
    def initialize(app_path)
      @app_path = app_path
    end

    private

    # (see .indent)
    def indent(code)
      self.class.indent(code)
    end
  end

  # @param app_path [String]
  def initialize(app_path)
    @app_path = app_path
    @code_blocks = []
  end

  # @param steps [Array<PostInstallScript::Step>]
  # @return [void]
  def add_steps(*steps)
    @code_blocks += steps.filter_map { |step| step.new(@app_path).call }
  end

  # @return [Boolean]
  def any_code_blocks?
    !@code_blocks.empty?
  end

  # @return [void]
  def create
    text = ErbEval.call(FILE_TEMPLATE, steps: @code_blocks)

    Dir.chdir(@app_path) do
      File.write(FILE_NAME, text)
      File.chmod(0o755, FILE_NAME) # rwxr-xr-x
    end
  end

  # @return [void]
  def run
    Dir.chdir(@app_path) { system(FILE_NAME) }
  end

  # @return [void]
  def remove
    Dir.chdir(@app_path) { File.unlink(FILE_NAME) }
  end

  FILE_NAME = "bin/postinstall"

  FILE_TEMPLATE = <<~ERB.freeze
    #!/usr/bin/env ruby
    # frozen_string_literal: true

    Dir.chdir(File.dirname(__dir__)) do
      unless system("bundle check")
        raise "You should run `bundle install` and then `bin/postinstall`"
      end
      if Dir.exist?(".tools") && !system("cd .tools && bundle check")
        raise "You should run `cd .tools && bundle install && cd ..` and then `bin/postinstall`"
      end

      section = ->(name) { puts("", name, "-" * name.size, "") }

    <%= steps.join("\n\n") %>
    end

    puts "Now you may delete file #{FILE_NAME}"
  ERB

  private_constant :FILE_NAME, :FILE_TEMPLATE
end
