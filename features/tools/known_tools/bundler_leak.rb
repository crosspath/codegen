# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class BundlerLeak < KnownTool
      register_as "Bundler Leak"

      def call(_use_tools)
        puts "Add Bundler Leak..."

        copy_files_to_project("bin/bundle-leak", DIR_BIN)
      end
    end
  end
end
