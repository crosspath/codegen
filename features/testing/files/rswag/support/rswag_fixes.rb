# frozen_string_literal: true

module RswagFixes
  module ExampleGroupHelpers
    def description(value = nil)
      return super() if value.nil?

      metadata[:operation][:description] = value.rstrip
    end
  end

  module RequestFactory
    # Rswag unable to generate correct OpenAPI schema for parameters in FormData.
    # This fix replaces behaviour of Rswag parser to the same as of body parameter.
    def build_form_payload(parameters, example)
      param = parameters.find { |pm| pm[:in] == :formData }
      example.public_send(extract_getter(param))
    end
  end
end

Rswag::Specs::ExampleGroupHelpers.prepend(RswagFixes::ExampleGroupHelpers)
Rswag::Specs::RequestFactory.prepend(RswagFixes::RequestFactory)
