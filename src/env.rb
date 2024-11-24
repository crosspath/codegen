# frozen_string_literal: true

# Helper methods for reading ENV values.
module Env
  extend self

  # @return [Boolean]
  def testing?
    ENV.fetch("TESTING", "0") != "0"
  end

  # @return [Boolean]
  def system_ruby?
    return @system_ruby if defined?(@system_ruby)

    @system_ruby = !File.writable?(Gem.paths.home)
  end

  # @return [String]
  def user
    ENV.fetch("USER")
  end
end
