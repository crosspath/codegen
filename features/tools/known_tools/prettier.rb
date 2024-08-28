# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class Prettier < KnownTool
      register_as "Prettier (code formatter)", adds_config: true

      def call(_use_tools)
        puts "Add Prettier..."

        copy_files_to_project("config/.prettierrc", DIR_CONFIG)
        copy_files_to_project("bin/prettier", DIR_BIN)

        run_command_in_project_dir("yarn add --dev --exact prettier")
      end
    end
  end
end
