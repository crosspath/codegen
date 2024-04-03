# frozen_string_literal: true

module Features::Tools::KnownTools
  class Solargraph < Features::Tools::KnownTool
    register_as "Solargraph (linter for types in Ruby)", adds_config: true

    def call(_use_tools)
      puts "Add Solargraph..."

      copy_files_to_project("config/.solargraph.yml", DIR_CONFIG)
      copy_files_to_project("bin/solargraph", DIR_BIN)
      copy_files_to_project("tasks", "lib/tasks")

      puts "Update settings for integration between Solargraph and VS Code..."

      if project_file_exist?(".vscode/settings.json")
        file_path = File.join(feature_dir, "files", "vscode/settings.json")
        existing_settings = read_project_file(".vscode/settings.json")
        new_settings = merge_jsons(existing_settings, File.read(file_path))
        write_project_file(".vscode/settings.json", new_settings)
      else
        copy_files_to_project("vscode", ".vscode")
      end

      add_gem_for_development("rails-annotate-solargraph")

      puts "Add documentation schema file to `.gitignore`..."

      update_ignore_file(".gitignore", add: ".annotate_solargraph_schema")

      puts "Copy documentation schema file..."

      copy_files_to_project(".annotate_solargraph_schema", "")
    end

    private

    def merge_jsons(*files)
      result = file_paths.map { |f| JSON.parse(f) }.reduce(&:merge)
      JSON.pretty_generate(result)
    end
  end
end
