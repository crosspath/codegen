# frozen_string_literal: true

require "io/console"

Dir.glob("#{__dir__}/questions/*.rb", sort: true).each { |f| require_relative(f) }

# Helper class for collecting user preferences for new application or for applying changes
# to existing application.
class Ask
  TYPES = {
    boolean: Questions::Boolean,
    many_of: Questions::ManyOf,
    one_of: Questions::OneOf,
    text: Questions::Text,
  }.freeze

  # @param gopt [Hash<Symbol, String | Boolean | Array<String>>] GeneratorOptions
  # @param ropt [Hash<String, String | Boolean | Array<String>>] RailsOptions
  def initialize(gopt, ropt)
    @gopt = gopt
    @ropt = ropt
  end

  # `GeneratorOptions` - (see #initialize)
  # `RailsOptions` - (see #initialize)
  # `OptionValue` is `String | Boolean | Array<String>`.
  # @param definition [Hash<Symbol, Object>] See below
  # @option definition [String] :label
  # @option definition [Symbol] :type - :text | :boolean | :one_of | :many_of
  # @option definition [Hash<String, String>] :variants - if type == :one_of || type == :many_of
  # @option definition [Proc(GeneratorOptions, RailsOptions) -> OptionValue] :default - optional
  # @option definition [Proc(GeneratorOptions, RailsOptions, OptionValue)] :apply - optional
  # @option definition [Proc(GeneratorOptions, RailsOptions) -> true | false] :skip_if - optional
  # @return [OptionValue]
  def question(definition)
    klass = TYPES.fetch(definition[:type]) { raise ArgumentError, definition[:type].to_s }
    klass.new(definition, @gopt, @ropt).call
  end
end
