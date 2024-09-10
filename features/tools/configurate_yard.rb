# frozen_string_literal: true

require_relative "../../src/post_install_script"

module Features
  module Tools
    class ConfigurateYard < PostInstallScript::Step
      def call
        indent(STEP)
      end

      STEP = <<~RUBY
        puts "Configurate YARD..."
        `bin/yard config --gem-install-yri`
      RUBY

      private_constant :STEP
    end
  end
end
