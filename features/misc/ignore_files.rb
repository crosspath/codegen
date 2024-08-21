# frozen_string_literal: true

module Features
  module Misc
    class IgnoreFiles < Feature
      def call
        IGNORE_FILES.each do |file_name|
          puts "Updating #{file_name} file..."
          update_ignore_file(file_name, add: IGNORE_FILE_ENTRIES)
        end
      end

      IGNORE_FILES = %w[.gitignore .dockerignore].freeze

      IGNORE_FILE_ENTRIES = [
        "*.local",
        ".DS_Store",
        ".directory",
        "Thumbs.db",
        "[Dd]esktop.ini",
        "~$*",
      ].freeze

      private_constant :IGNORE_FILES, :IGNORE_FILE_ENTRIES
    end
  end
end
