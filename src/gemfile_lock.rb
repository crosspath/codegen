# frozen_string_literal: true

# Helper class fo reading `Gemfile.lock` file.
class GemfileLock
  # @param dir [String]
  def initialize(dir)
    @lines = File.read(File.join(dir, "Gemfile.lock")).split("\n")
  end

  # @return [String]
  def bundler_version
    index = @lines.find_index("BUNDLED WITH")
    return @lines[index + 1].strip if index

    require "bundler"
    Bundler::VERSION
  end

  # @param word [String]
  # @return [Boolean]
  def includes?(word)
    !@lines.grep(/^\s*#{word}\s/).empty?
  end

  # @return [Array<String>]
  def gems
    lines = @lines.dup
    result = []

    loop do
      # +3 means "skip lines 'GEM', 'remote', 'specs'"
      gem_list_index = lines.find_index { |line| line == "GEM" }&.+(3)
      break unless gem_list_index

      lines = lines[gem_list_index..]
      result += lines.take_while { |line| !line.empty? }
    end

    raise "Cannot find 'GEM' section in Gemfile.lock" if result.empty?

    result.map { |line| line[/\S+/] }
  end
end
