# frozen_string_literal: true

module Features
  class SortConfig < Feature
    register_as "sort-config"

    def call
      project_files("", "config/environments/*.rb").each do |file|
        puts "Update #{file} file..."
        sort_config_lines(file)
      end
    end

    private

    def extract_blocks(lines)
      nested_block    = false
      prev_has_config = true
      after_new_line  = true

      lines.reduce([]) do |a, e|
        if e.strip.empty?
          after_new_line = true
          next a
        end

        if e.match(/\A(\s*)/)[1].size == 2
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

        prev_has_config = a.last.split("\n").any? { |x| x =~ /\A\s*config\.[\w._]+/ }
        after_new_line  = false

        a
      end
    end

    def sort_config_lines(file_name)
      file = read_project_file(file_name)

      sections = file.match(/\A(.*Rails\.application\.configure do\n)(.*)(\nend[\n\Z].*)/m)
      return unless sections

      blocks = extract_blocks(sections[2].split("\n"))

      blocks.sort_by! { |x| x.match(/config\.([\w._]+)/m)&.[](1) || '' }

      blocks_with_marks = blocks.map do |e|
        {oneline: e.split("\n").size == 1, text: e}
      end

      joined = blocks_with_marks.reduce([]) do |a, e|
        if a.empty?
          [e]
        else
          if a.last[:oneline] && e[:oneline]
            a << {oneline: true, text: "#{a.pop[:text]}\n#{e[:text]}"}
          else
            a << e
          end
        end
      end

      inner = joined.map { |x| x[:text] }.join("\n\n")

      result = [sections[1], inner, sections[3]].join.gsub("\n\n\n", "\n\n")

      write_project_file(file_name, result)
    end
  end
end
