# frozen_string_literal: true

require_relative "../../src/post_install_script"

module Features
  module Tools
    class AutofixCode < PostInstallScript::Step
      def call
        indent(STEP)
      end

      STEP = <<~RUBY
        RULES = %w[
          Layout/EmptyLineAfterMagicComment
          Style/FrozenStringLiteralComment
          Style/GlobalStdStream
          Style/MutableConstant
        ].freeze
        run_and_show_stats =
          ->(command) do
            puts "+ \#{command}"
            output = `\#{command}`
            res =
              output.lines.reverse.find do |line|
                lines.include?("files inspected") || lines.include?("file inspected")
              end
            res ? puts(res) : puts(output)
          end
        run_and_show_all =
          ->(command) do
            puts "+ \#{command}"
            system(command)
          end
        run_and_show_stats.call("bin/rubocop -a") # Apply "safe" corrections.
        run_and_show_stats.call("bin/rubocop --only \#{RULES.join(",")} -A")
        run_and_show_all.call("bin/rubocop") # Fix manually all the rest issues.
      RUBY

      private_constant :STEP
    end
  end
end
