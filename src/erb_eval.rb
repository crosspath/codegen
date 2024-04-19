# frozen_string_literal: true

require "erubi"

module ErbEval
  def self.call(text, **vars)
    b = binding
    vars.each { |k, v| b.local_variable_set(k, v) }

    b.eval(Erubi::Engine.new(text, trim_mode: "%<>").src)
  end
end
