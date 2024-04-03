# frozen_string_literal: true

module Features::Tools::KnownTools
  class Rubocop < Features::Tools::KnownTool
    register_as "Rubocop (linter & formatter for Ruby)", adds_config: true

    GEMS = %w[capybara factory_bot graphql rspec sequel].freeze

    def call(_use_tools)
      puts "Add Rubocop..."

      gems = GEMS.to_h { |x| [x, @gems.include?(x)] }

      erb("config/rubocop", File.join(DIR_CONFIG, "rubocop.yml"), **gems)
      copy_files_to_project("config/rubocop-in-templates.yml", DIR_CONFIG)
      copy_files_to_project("bin/rubocop", DIR_BIN)
    end
  end
end
