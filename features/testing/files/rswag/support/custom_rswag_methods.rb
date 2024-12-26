# frozen_string_literal: true

# For Swagger / OpenAPI specs.
module CustomRswagMethods
  # @param kwargs [Hash]
  # @option :properties [Hash<Symbol, Hash>]
  # @option :required [Array<String | Symbol>]
  # @return [void]
  def body_parameter(**kwargs)
    parameter(name: :body, in: :body, schema: {type: :object, **kwargs})
  end

  # @param name [String, Symbol]
  # @param properties [Hash<Symbol | String, Object>]
  # @param kw [Hash<Symbol, Object>]
  # @return [void]
  def group_parameter(name, properties:, **kw)
    parameter(name:, style: "deepObject", **kw, schema: {type: "object", properties:})
  end

  # @see rswag/specs/example_group_helpers.rb
  # @param verb [Symbol] :get, :post, :patch, :put, :delete, :head, :options, :trace
  # @param app_path [String]
  # @param summary [String]
  # @return [void]
  def request(verb, app_path, summary, &block)
    tag_list = metadata[:tags]

    describe(app_path, {path_item: {template: app_path}}) do
      describe(verb, {operation: {verb:, summary:}}) do
        consumes("application/json") if %i[post patch put].include?(verb)
        produces("application/json")
        tags(*tag_list) if tag_list.present?

        instance_eval(&block)
      end
    end
  end
end

Rswag::Specs::ExampleGroupHelpers.include(CustomRswagMethods)
