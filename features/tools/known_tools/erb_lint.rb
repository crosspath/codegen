# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class ERBLint < KnownTool
      register_as "ERB Lint", adds_config: true

      def call(use_tools)
        puts "Add ERB Lint..."

        rubocop = use_tools["rubocop"]

        erb("config/.erb-lint", File.join(DIR_CONFIG, ".erb-lint.yml"), rubocop:)
        copy_files_to_project("bin/erblint", DIR_BIN)
      end
    end
  end
end
