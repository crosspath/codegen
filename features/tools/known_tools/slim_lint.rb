# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class SlimLint < KnownTool
      register_as "Slim Lint", adds_config: true

      def call(_use_tools)
        puts "Add Slim Lint..."

        copy_files_to_project("config/.slim-lint.yml", DIR_CONFIG)
        copy_files_to_project("bin/slimlint", DIR_BIN)
      end

      def use?
        @gems["slim"] && super
      end
    end
  end
end
