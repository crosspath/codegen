# frozen_string_literal: true

# Helper methods for reading ENV values.
module Env
  extend self

  MIN_RAILS_VERSION = "7.2"

  # @return [Boolean]
  def no_save?
    ENV.fetch("NO_SAVE", "0") != "0"
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
