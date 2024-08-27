# frozen_string_literal: true

module Features
  class SortConfig < Feature
    register_as "sort-config"

    def call
      project_files("", "config/environments/*.rb").each do |file|
        puts "Update #{file} file..."
        sort_config_lines_in_file(file)
      end
    end

    private

    RE_CONFIG = /\A\s*config\.[\w._]+/
    RE_CONFIG_WITH_CAPTURE = /config\.([\w._]+)/m
    RE_FILE = /\A(.*Rails\.application\.configure do\n)(.*)(\nend[\n\Z].*)/m
    RE_SPACES = /\A(\s*)/

    private_constant :RE_CONFIG, :RE_CONFIG_WITH_CAPTURE, :RE_FILE, :RE_SPACES

    def extract_blocks(lines)
      nested_block = false
      prev_has_config = true
      after_new_line = true

      lines.each_with_object([]) do |e, a|
        if e.strip.empty?
          after_new_line = true
          next
        end

        if e.match(RE_SPACES)[1].size == 2
          if nested_block # `else`, `end`, ...
            a << "#{a.pop}\n#{e}"
            nested_block = false
          elsif prev_has_config || after_new_line
            a << e
          else # для комментариев перед строкой `config`
            a << "#{a.pop}\n#{e}"
          end
        else
          a << "#{a.pop}\n#{e}"
          nested_block = true
        end

        prev_has_config = a.last.split("\n").any? { |x| x =~ RE_CONFIG }
        after_new_line = false
      end
    end

    def sort_config_lines_in_file(file_name)
      file = read_project_file(file_name)

      sections = file.match(RE_FILE)
      return unless sections

      inner = sort_lines(sections[2].split("\n"))
      result = [sections[1], inner, sections[3]].join.gsub("\n\n\n", "\n\n")

      write_project_file(file_name, result)
    end

    def sort_lines(lines)
      blocks = extract_blocks(lines)

      blocks.sort_by! { |x| x.match(RE_CONFIG_WITH_CAPTURE)&.[](1) || "" }

      join_blocks(blocks).map { |x| x[:text] }.join("\n\n")
    end

    def join_blocks(blocks)
      blocks_with_marks = blocks.map { |e| {oneline: e.split("\n").size == 1, text: e} }

      blocks_with_marks.reduce([]) do |a, e|
        if a.empty?
          [e]
        elsif a.last[:oneline] && e[:oneline]
          a << {oneline: true, text: "#{a.pop[:text]}\n#{e[:text]}"}
        else
          a << e
        end
      end
    end
  end
end
