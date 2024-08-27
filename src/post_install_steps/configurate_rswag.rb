module PostInstallSteps
  class ConfigurateRswag < Base
    def call
      indent(RSWAG_INSTALLATION)
    end

    private

    RSWAG_INSTALLATION = <<~RUBY
      puts "Add RSwag..."
      `bin/rails g rswag:api:install`
      `bin/rails g rswag:ui:install`
      `RAILS_ENV=test bin/rails g rswag:specs:install`
      swagger_helper =
        File.read("spec/swagger_helper.rb")
          .sub("https:", "http:")
          .sub("www.example.com", "localhost:3000")
      File.write("spec/swagger_helper.rb", swagger_helper)
    RUBY

    private_constant :RSWAG_INSTALLATION
  end
end
