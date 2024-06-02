# frozen_string_literal: true

require "erb"

module ErbEval
  def self.call(text, **vars)
    b = binding
    vars.each { |k, v| b.local_variable_set(k, v) }

    ERB.new(text, trim_mode: "%<>").result(b)
  end
end
