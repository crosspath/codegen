# frozen_string_literal: true

require "io/console"

Dir.glob("#{__dir__}/questions/*.rb", sort: true).each { |f| require_relative(f) }

class Ask
  Interrupt = Class.new(RuntimeError).freeze

  KEYS = (("1".."9").to_a + ("a".."z").to_a).freeze

  TYPES = {
    boolean: Questions::Boolean,
    many_of: Questions::ManyOf,
    one_of: Questions::OneOf,
    text: Questions::Text,
  }.freeze

  def initialize(gopt, ropt)
    @gopt = gopt
    @ropt = ropt
  end

  def question(definition)
    klass = TYPES.fetch(definition[:type]) { raise ArgumentError, definition[:type].to_s }
    klass.new(definition, @gopt, @ropt).call
  end
end
