# frozen_string_literal: true

module Env
  extend self

  def no_save?
    ENV.fetch("NO_SAVE", "0") != "0"
  end

  def root_dir
    @root_dir ||= File.expand_path("..", __dir__)
  end

  def user
    ENV.fetch("USER")
  end
end
