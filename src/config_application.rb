# frozen_string_literal: true

# Helper class fo reading `config/application.rb` file.
class ConfigApplication
  attr_reader :lines

  # @param dir [String]
  def initialize(dir)
    @file_path = File.join(dir, FILE)
    @lines = File.read(@file_path).split("\n")
  end

  # @param lines [Array<String>]
  # @return [void]
  def append_to_body(lines)
    last_index = index_of_line_starting_with("end")
    error_no_match("last end of module") unless last_index

    @lines.insert(last_index - 1, "", *StringUtils.indent(lines, 2))
    save_lines_into_file
  end

  # @param lines [Array<String>]
  # @return [void]
  def append_to_requires(lines)
    last_index = index_of_line_starting_with("module")
    error_no_match("declaration of module") unless last_index

    @lines.insert(last_index, *lines, "")
    save_lines_into_file
  end

  private

  FILE = "config/application.rb"

  private_constant :FILE

  def error_no_match(substring)
    raise "Cannot find #{substring} in #{FILE}"
  end

  def index_of_line_starting_with(substring)
    @lines.find_index { |line| line.start_with?(substring) }
  end

  def save_lines_into_file
    File.write(@file_path, @lines.join("\n"))
  end
end
