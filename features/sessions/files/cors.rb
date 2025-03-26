# frozen_string_literal: true

Rails.application.config.middleware.insert_before(0, Rack::Cors) do
  allow do # For API-only application, JWT.
    origins("*")
    resource("*", expose: ["Authorization"], headers: :any, methods: :any)
  end
end
