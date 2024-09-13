# frozen_string_literal: true

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
        steps = [
          "bin/overcommit --sign",
          "bin/overcommit --sign pre-commit",
        ]
        steps << "bin/overcommit --sign post-checkout" if options[:post_checkout]
        steps << "bin/overcommit --sign post-commit" if options[:post_commit]

        text = 'section.call("Sign scripts for Overcommit...")'.dup
        text << "\n#{steps.map { |x| "`#{x}`\n" }.join}"

        indent(text)
      end

      def options
        {}
      end
    end
  end
end
