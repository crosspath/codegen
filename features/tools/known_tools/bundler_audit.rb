# frozen_string_literal: true

module Features::Tools::KnownTools
  class BundlerAudit < Features::Tools::KnownTool
    register_as "Bundler Audit"

    def call(_use_tools)
      puts "Add Bundler Audit..."

      copy_files_to_project("bin/bundle-audit", DIR_BIN)
    end
  end
end
