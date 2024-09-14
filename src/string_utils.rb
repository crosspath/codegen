# frozen_string_literal: true

# Useful methods for strings.
module StringUtils
  extend self

  # @param name [String]
  # @return [void]
  def section(name)
    length = name.size

    puts
    puts name
    puts("-" * length)
    puts
  end

  # @param lines [Array<String>]
  # @return [void]
  def warning(lines)
    length = lines.map(&:size).max

    puts
    puts("=" * length)
    puts lines
    puts("-" * length)
    puts
  end

  # @param lines [Array<String>]
  # @param level [Integer]
  # @return [Array<String>]
  def indent(lines, level = 1)
    spaces = " " * (2 * level)
    lines.map { |x| x.empty? ? x : "#{spaces}#{x}" }
  end
end
