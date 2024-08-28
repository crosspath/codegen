# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class RailsBestPractices < KnownTool
      register_as "Rails Best Practices (linter for Ruby)", adds_config: true

      def call(_use_tools)
        puts "Add Rails Best Practices..."

        copy_files_to_project("config/rails_best_practices.yml", DIR_CONFIG)
        copy_files_to_project("bin/rails_best_practices", DIR_BIN)
      end
    end
  end
end
