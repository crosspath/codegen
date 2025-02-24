# frozen_string_literal: true

# For Swagger / OpenAPI specs.
module RswagMethods
  # @param kwargs [Hash]
  # @option :properties [Hash<Symbol, Hash>]
  # @option :required [Array<String | Symbol>]
  # @return [void]
  def body_parameter(**kwargs)
    parameter(name: :body, in: :body, schema: {type: :object, **kwargs})
  end

  # @param name [String, Symbol]
  # @param kwargs [Hash]
  # @option :properties [Hash<Symbol, Hash>]
  # @option :required [Array<String | Symbol>]
  # @return [void]
  def form_data_parameter(**kwargs)
    consumes("multipart/form-data")
    parameter(name: :body, in: :formData, schema: {type: :object, **kwargs})
  end

  # @param name [String, Symbol]
  # @param properties [Hash<Symbol | String, Object>]
  # @param kw [Hash<Symbol, Object>]
  # @return [void]
  def group_parameter(name, properties:, **kw)
    parameter(name:, style: "deepObject", **kw, schema: {type: :object, properties:})
  end

  # @see rswag/specs/example_group_helpers.rb
  # @param verb [Symbol] :get, :post, :patch, :put, :delete, :head, :options, :trace
  # @param app_path [String]
  # @param summary [String]
  # @param args [Array] Empty or `[:jwt]`
  # @return [void]
  def request(verb, app_path, summary, *args, &block)
    add_jwt = args.include?(:jwt) || metadata[:jwt]
    tag = metadata[:tags]

    summary_options = add_jwt ? "JWT" : ""
    summary = "[#{summary_options}] #{summary}" if !summary_options.empty?

    describe(app_path, {path_item: {template: app_path}}) do
      describe(verb, {operation: {verb:, summary:}}) do
        request_body_definition(verb, add_jwt, tag, &block)
      end
    end
  end

  private

  def request_body_definition(verb, add_jwt, tag, &)
    consumes("application/json") if %i[post patch put].include?(verb)
    produces("application/json")
    security([digest: []]) if add_jwt
    tags([tag]) if tag.present?

    instance_eval(&)
  end
end

Rswag::Specs::ExampleGroupHelpers.include(RswagMethods)
