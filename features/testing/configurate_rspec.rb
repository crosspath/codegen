# frozen_string_literal: true

require_relative "../../src/post_install_script"

module Features
  module Testing
    class ConfigurateRspec < PostInstallScript::Step
      def call
        indent(STEP)
      end

      STEP = <<~RUBY
        section.call("Add RSpec...")
        SPEC_FILE = <<~RUBY1
          # frozen_string_literal: true

          ENV["RAILS_ENV"] ||= "test"

          require File.expand_path("../config/environment", __dir__)
          return unless Rails.env.test?

          Dir[File.join(__dir__, "support/*.rb")].each { |f| require f }
        RUBY1
        `bin/rails g rspec:install`
        File.rename("spec/spec_helper.rb", "spec/support/core.rb")
        File.rename("spec/rails_helper.rb", "spec/support/rails.rb")
        rails_helper =
          File.readlines("spec/support/rails.rb").drop_while do |line|
            !line.match?(%r@^require ['"]rspec/rails['"]@)
          end
        File.write("spec/support/rails.rb", rails_helper.join)
        File.write("spec/spec_helper.rb", SPEC_FILE)
      RUBY

      private_constant :STEP
    end
  end
end
