# frozen_string_literal: true

module Features::Tools::KnownTools
  class Fasterer < Features::Tools::KnownTool
    register_as "Fasterer (linter for Ruby)", adds_config: true

    def call(_use_tools)
      puts "Add Fasterer..."

      copy_files_to_project("config/.fasterer.yml", DIR_CONFIG)
      copy_files_to_project("bin/fasterer", DIR_BIN)
    end
  end
end
