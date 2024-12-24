# frozen_string_literal: true

module CustomRswagMethods
  # @param kwargs [Hash]
  # @option :properties [Hash<Symbol, Hash>]
  # @option :required [Array<String | Symbol>]
  # @return [void]
  def body_parameter(**kwargs)
    consumes("application/json")
    parameter(name: :body, in: :body, schema: {type: :object, **kwargs})
  end
end

Rswag::Specs::ExampleGroupHelpers.include(CustomRswagMethods)
