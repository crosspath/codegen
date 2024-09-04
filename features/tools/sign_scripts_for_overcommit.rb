# frozen_string_literal: true

require_relative "../../src/erb_eval"
require_relative "../../src/post_install_script"

module Features
  module Tools
    class SignScriptsForOvercommit < PostInstallScript::Step
      def self.with_options(options)
        klass = Class.new(self)
        klass.define_method(:options) { options }
        klass
      end

      def call
        indent(ErbEval.call(STEP, options:))
      end

      def options
        {}
      end

      private

      STEP = <<~ERB
        puts "Sign scripts for Overcommit..."
        `bin/overcommit --sign`
        `bin/overcommit --sign pre-commit`
        <%= "`bin/overcommit --sign post-checkout`\n" if options[:post_checkout] %>
        <%= "`bin/overcommit --sign post-commit`" if options[:post_commit] %>
      ERB

      private_constant :STEP
    end
  end
end
