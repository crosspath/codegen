# frozen_string_literal: true

require_relative "../../src/post_install_script"

module Features
  module Testing
    class ConfigurateRswag < PostInstallScript::Step
      def call
        indent(STEP)
      end

      STEP = <<~RUBY
        section.call("Add RSwag...")
        `bin/rails g rswag:api:install`
        `bin/rails g rswag:ui:install`
        rswag_ui_file = "config/initializers/rswag_ui.rb"
        rswag_ui = File.read(rswag_ui_file).sub("swagger_endpoint", "openapi_endpoint")
        File.write(rswag_ui_file, rswag_ui)
        `RAILS_ENV=test bin/rails g rswag:specs:install`
        swagger_helper_file = "spec/swagger_helper.rb"
        swagger_helper =
          File.read(swagger_helper_file)
            .sub("require 'rails_helper'", 'require "spec_helper"')
            .sub("https:", "http:")
            .sub("www.example.com", "localhost:3000")
        File.write(swagger_helper_file, swagger_helper)
        rswag_api_file = "config/initializers/rswag_api.rb"
        config = File.read(rswag_api_file)
        config.sub!("Rails.root.to_s + '/swagger'", 'Rails.root.join("/swagger")')
        File.write(rswag_api_file, config)
      RUBY

      private_constant :STEP
    end
  end
end
