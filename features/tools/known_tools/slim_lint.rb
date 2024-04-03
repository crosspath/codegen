# frozen_string_literal: true

module Features::Tools::KnownTools
  class SlimLint < Features::Tools::KnownTool
    register_as "Slim Lint", adds_config: true

    def call(_use_tools)
      puts "Add Slim Lint..."

      copy_files_to_project("config/.slim-lint.yml", DIR_CONFIG)
      copy_files_to_project("bin/slimlint", DIR_BIN)
    end

    def use?
      @gems.include?("slim") && super
    end
  end
end
