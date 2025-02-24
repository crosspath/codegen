# frozen_string_literal: true

require_relative "../configurate_yard"

module Features::Tools
  module KnownTools
    class Yard < KnownTool
      register_as "YARD (code documentation tool)"

      def call(_use_tools)
        puts "Add YARD..."

        copy_files_to_project("bin/yard", DIR_BIN)
        update_ignore_files

        cli.post_install_script.add_steps(ConfigurateYard)
      end

      def use?
        ToolRegistry.all["solargraph"].selected || super
      end

      private

      IGNORE_FILES = %w[.gitignore .dockerignore].freeze

      private_constant :IGNORE_FILES

      def update_ignore_files
        IGNORE_FILES.each do |file_name|
          next unless project_file_exist?(file_name)

          update_ignore_file(file_name, add: ["/doc", "/.yardoc"])
        end
      end
    end
  end
end
