# frozen_string_literal: true

require_relative "../../src/post_install_script"

module Features
  module Testing
    class ConfigurateRswag < PostInstallScript::Step
      def call
        indent(STEP)
      end

      private

      STEP = <<~RUBY
        puts "Add RSwag..."
        `bin/rails g rswag:api:install`
        `bin/rails g rswag:ui:install`
        rswag_ui_file = "config/initializers/rswag_ui.rb"
        File.write(rswag_ui_file, File.read(rswag_ui_file).sub("swagger_endpoint", "openapi_endpoint"))
        `RAILS_ENV=test bin/rails g rswag:specs:install`
        swagger_helper =
          File.read("spec/swagger_helper.rb")
            .sub("https:", "http:")
            .sub("www.example.com", "localhost:3000")
        File.write("spec/swagger_helper.rb", swagger_helper)
      RUBY

      private_constant :STEP
    end
  end
end
