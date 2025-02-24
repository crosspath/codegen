# frozen_string_literal: true

module RswagFixes # rubocop:disable Style/ClassAndModuleChildren
  module RequestFactory
    # Rswag unable to generate correct OpenAPI schema for parameters in FormData.
    # This fix replaces behaviour of Rswag parser to the same as of body parameter.
    def build_form_payload(parameters, example)
      param = parameters.find { |pm| pm[:in] == :formData }
      example.public_send(extract_getter(param))
    end
  end
end

Rswag::Specs::RequestFactory.prepend(RswagFixes::RequestFactory)
