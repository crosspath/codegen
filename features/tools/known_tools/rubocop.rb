# frozen_string_literal: true

module Features::Tools
  module KnownTools
    class Rubocop < KnownTool
      register_as "Rubocop (linter & formatter for Ruby)", adds_config: true

      GEMS = %w[capybara factory_bot graphql rspec rswag sequel].freeze

      def call(_use_tools)
        puts "Add Rubocop..."

        gems = GEMS.to_h { |x| [x, @gems[x]] }

        erb("config/rubocop", File.join(DIR_CONFIG, "rubocop.yml"), **gems)
        copy_files_to_project("config/rubocop-in-templates.yml", DIR_CONFIG)
        copy_files_to_project("bin/rubocop", DIR_BIN)
      end
    end
  end
end
