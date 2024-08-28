# frozen_string_literal: true

require_relative "../configurate_yard"

module Features::Tools
  module KnownTools
    class Yard < KnownTool
      register_as "YARD (code documentation tool)"

      def call(_use_tools)
        puts "Add YARD..."

        copy_files_to_project("bin/yard", DIR_BIN)

        cli.post_install_script.add_steps(ConfigurateYard)
      end

      def use?
        ToolRegistry.all["solargraph"].selected || super
      end
    end
  end
end
