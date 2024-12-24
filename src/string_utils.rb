# frozen_string_literal: true

# Useful methods for strings.
module StringUtils
  extend self

  # @param str [String] StringWithCapitalLetters
  # @param [String] string_with_underscores
  def capitalize_to_underscores(str)
    str.scan(/[A-Z][a-z\d]*/).map(&:downcase).join("_")
  end

  # @param lines [Array<String>]
  # @param level [Integer]
  # @return [Array<String>]
  def indent(lines, level = 1)
    spaces = " " * (2 * level)
    lines.map { |x| x.empty? ? x : "#{spaces}#{x}" }
  end

  # @param name [String]
  # @return [void]
  def section(name)
    length = name.size

    puts
    puts name
    puts("-" * length)
    puts
  end

  # @param str [String] string_with_underscores
  # @param [String] StringWithCapitalLetters
  def underscores_to_capitalize(str)
    words = str.split("_")
    words.map! do |word|
      word[0] = word[0].upcase
      word
    end
    words.join
  end

  # @param str [String] string_with_underscores
  # @param [String] String With Capital Letters
  def underscores_to_titleize(str)
    words = str.split("_")
    words.map! do |word|
      word[0] = word[0].upcase
      word
    end
    words.join(" ")
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

  # @param str [String]
  # @return [Boolean]
  def with_capitalize?(str)
    ("A".."Z").cover?(str[0])
  end

  # @param str [String]
  # @return [Boolean]
  # def with_underscores?(str)
  #   str.include?("_")
  # end
end
