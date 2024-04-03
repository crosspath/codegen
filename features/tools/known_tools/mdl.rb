# frozen_string_literal: true

module Features::Tools::KnownTools
  class Mdl < Features::Tools::KnownTool
    register_as "MDL (for Markdown files)", adds_config: true

    def call(_use_tools)
      puts "Add MDL..."

      copy_files_to_project("config/mdl_style.rb", DIR_CONFIG)
      copy_files_to_project("bin/mdl", DIR_BIN)
    end
  end
end
