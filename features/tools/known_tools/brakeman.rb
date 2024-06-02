# frozen_string_literal: true

module Features::Tools::KnownTools
  class Brakeman < Features::Tools::KnownTool
    register_as "Brakeman (linter for Ruby)", adds_config: true

    def call(_use_tools)
      puts "Add Brakeman..."

      copy_files_to_project("config/brakeman.yml", DIR_CONFIG)
      copy_files_to_project("bin/brakeman", DIR_BIN)
    end
  end
end
