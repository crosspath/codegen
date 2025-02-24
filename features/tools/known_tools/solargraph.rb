# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class Solargraph < KnownTool
      register_as "Solargraph (linter for types in Ruby)", adds_config: true

      def call(_use_tools)
        puts "Add Solargraph..."
        copy_files_for_solargraph

        puts "Update settings for integration between Solargraph and VS Code..."
        update_vs_code_settings
        add_gem_for_development(
          "rails-annotate-solargraph",
          github: "crosspath/rails-annotate-solargraph"
        )

        puts "Add documentation schema file to .gitignore & .dockerignore files..."
        update_ignore_files

        puts "Copy documentation schema file..."
        copy_files_to_project(".annotate_solargraph_schema", "")
      end

      private

      IGNORE_FILES = %w[.gitignore .dockerignore].freeze
      NEW_VS_CODE_SETTINGS = {"solargraph.commandPath" => "bin/solargraph"}.freeze
      VS_CODE_SETTINGS_FILE = ".vscode/settings.json"

      private_constant :IGNORE_FILES, :NEW_VS_CODE_SETTINGS, :VS_CODE_SETTINGS_FILE

      def copy_files_for_solargraph
        copy_files_to_project("config/.solargraph.yml", DIR_CONFIG)
        copy_files_to_project("bin/solargraph", DIR_BIN)
        copy_files_to_project("tasks", "lib")
      end

      def update_vs_code_settings
        create_project_dir(".vscode")

        existing_settings = {}
        if project_file_exist?(VS_CODE_SETTINGS_FILE)
          existing_settings = JSON.parse(read_project_file(VS_CODE_SETTINGS_FILE))
        end

        new_settings = existing_settings.merge(NEW_VS_CODE_SETTINGS)
        write_project_file(VS_CODE_SETTINGS_FILE, JSON.pretty_generate(new_settings))
      end

      def update_ignore_files
        IGNORE_FILES.each do |file_name|
          next unless project_file_exist?(file_name)

          update_ignore_file(file_name, add: [".annotate_solargraph_schema"])
        end
      end
    end
  end
end
