# frozen_string_literal: true

require "erb"

# Helper method for rendering ERB-templates.
module ErbEval
  # @param text [String]
  # @param vars [Hash<String, Object>]
  # @return [String]
  def self.call(text, **vars)
    b = binding
    vars.each { |k, v| b.local_variable_set(k, v) }

    ERB.new(text, trim_mode: "%<>").result(b)
  end
end
