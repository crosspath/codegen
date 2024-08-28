# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class ESLint < KnownTool
      register_as "ESLint", adds_config: true

      def call(_use_tools)
        puts "Add ESLint..."

        copy_files_to_project("config/eslint.config.js", DIR_CONFIG)
        copy_files_to_project("bin/eslint", DIR_BIN)

        # run_command_in_project_dir("yarn add --dev eslint@next") # v9+
        run_command_in_project_dir("yarn add --dev eslint")
      end
    end
  end
end
