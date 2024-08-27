# frozen_string_literal: true

module Env
  extend self

  MIN_RAILS_VERSION = "7.2"

  def no_save?
    ENV.fetch("NO_SAVE", "0") != "0"
  end

  def system_ruby?
    return @system_ruby if defined?(@system_ruby)

    @system_ruby = !File.writable?(Gem.paths.home)
  end

  def user
    ENV.fetch("USER")
  end
end
