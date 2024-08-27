# frozen_string_literal: true

module Features
  module Misc
    class BinScripts < Feature
      def call
        puts "Update bin/setup file..."
        update_bin_setup

        puts "Updating bin scripts if needed..."
        update_bin_scripts
      end

      private

      BIN_SETUP = "bin/setup"

      BIN_SETUP_BEFORE = <<~RUBY
        puts "\\n== Preparing database =="
        system! "bin/rails db:prepare"

        puts "\\n== Removing old logs and tempfiles =="
        system! "bin/rails log:clear tmp:clear"

        puts "\\n== Restarting application server =="
        system! "bin/rails restart"
      RUBY

      BIN_SETUP_AFTER = <<~RUBY
        puts "\\n== Preparing database =="
        system! "bin/rails db:prepare log:clear tmp:clear"
      RUBY

      RE_HASH_BANG_LINE = /\A\s*\#!.*ruby/
      DEFAULT_HASH_BANG_LINE = "#!/usr/bin/env ruby"
      RE_FROZEN_STRING_LITERAL = /\A\s*\#\s*frozen[_-]string[_-]literal:/i
      FROZEN_STRING_LITERAL_LINE = "# frozen_string_literal: true"

      private_constant :BIN_SETUP, :BIN_SETUP_BEFORE, :BIN_SETUP_AFTER, :RE_HASH_BANG_LINE
      private_constant :DEFAULT_HASH_BANG_LINE, :RE_FROZEN_STRING_LITERAL
      private_constant :FROZEN_STRING_LITERAL_LINE

      def update_bin_setup
        bin_setup = read_project_file(BIN_SETUP)
        text_before = indent(BIN_SETUP_BEFORE.split("\n")).join("\n")
        text_after = indent(BIN_SETUP_AFTER.split("\n")).join("\n")

        bin_setup.sub!(text_before, text_after)
        write_project_file(BIN_SETUP, bin_setup)
      end

      def update_bin_scripts
        project_files("", "bin/*").each do |file_name|
          lines = read_project_file(file_name).split("\n")

          if change_header_in_bin_script(lines)
            puts "Updating #{file_name} file..."
            write_project_file(file_name, lines.join("\n"))
          end
        end
      end

      def change_header_in_bin_script(lines)
        return false unless lines.first.match?(RE_HASH_BANG_LINE)

        first = replace_hash_bang_line_if_needed(lines)
        second = add_frozen_string_literal_line_if_needed(lines)

        first || second
      end

      def replace_hash_bang_line_if_needed(lines)
        return false if lines.first == DEFAULT_HASH_BANG_LINE

        lines.first.replace(DEFAULT_HASH_BANG_LINE)
        true
      end

      def add_frozen_string_literal_line_if_needed(lines)
        second_line = lines[1]
        return false if second_line.match?(RE_FROZEN_STRING_LITERAL)

        lines.insert(1, FROZEN_STRING_LITERAL_LINE)
        true
      end
    end
  end
end
