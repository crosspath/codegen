# frozen_string_literal: true

module Features::Tools::KnownTools
  class BundlerLeak < Features::Tools::KnownTool
    register_as "Bundler Leak"

    def call(_use_tools)
      puts "Add Bundler Leak..."

      copy_files_to_project("bin/bundle-leak", DIR_BIN)
    end
  end
end
