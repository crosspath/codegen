# frozen_string_literal: true

module StringUtils
  extend self

  def warning(lines)
    length = lines.map(&:size).max

    puts
    puts("=" * length)
    puts lines
    puts("-" * length)
    puts
  end

  def indent(lines, level = 1)
    spaces = " " * (2 * level)
    lines.map { |x| x.empty? ? x : "#{spaces}#{x}" }
  end
end
