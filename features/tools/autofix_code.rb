# frozen_string_literal: true

require_relative "../../src/post_install_script"

module Features
  module Tools
    class AutofixCode < PostInstallScript::Step
      def call
        indent(STEP)
      end

      STEP = <<~RUBY
        puts 'Apply "safe" corrections from RuboCop...'
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
                line.include?("files inspected") || line.include?("file inspected")
              end
            puts(res || output)
          end
        run_and_show_stats.call("bin/rubocop -a")
        run_and_show_stats.call("bin/rubocop -A --only \#{RULES.join(",")}")
      RUBY

      private_constant :STEP
    end
  end
end
