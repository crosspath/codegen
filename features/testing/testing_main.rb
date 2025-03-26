# frozen_string_literal: true

require_relative "configurate_rspec"
require_relative "configurate_rswag"

module Features
  module Testing
    class TestingMain < Feature
      register_as "testing tools"

      def call
        use_rswag = add_rswag?

        puts "Add gems to Gemfile..."
        add_gems_for_testing(use_rswag)

        puts "Copy configuration files..."
        copy_configuration_files(use_rswag)

        puts "Apply configuration..."
        update_config_application
      end

      private

      GROUP_DEV_TEST = %i[development test].freeze

      GENERATORS = <<~RUBY
        config.generators do |g|
          g.factory_bot(dir: "factories", filename_proc: ->(t) { t.singularize })
        end
      RUBY

      private_constant :GROUP_DEV_TEST, :GENERATORS

      def add_gems_for_testing(use_rswag)
        if use_rswag
          add_gem("rswag-api", "rswag-ui")
          add_gem("factory_bot_rails", "rspec-rails", "rswag-specs", group: GROUP_DEV_TEST)
        else
          add_gem("factory_bot_rails", "rspec-rails", group: GROUP_DEV_TEST)
        end
      end

      def copy_configuration_files(use_rswag)
        cli.post_install_script.add_steps(ConfigurateRspec)
        copy_files_to_project("bin", "")

        if use_rswag
          copy_files_to_project("rswag/bin", "")
          copy_files_to_project("rswag/support", "spec/")
          cli.post_install_script.add_steps(ConfigurateRswag)
        end

        copy_spec_support
      end

      def add_rswag?
        cli.ask.question(
          type: :boolean,
          label: "Add rswag (OpenAPI 3.0+)",
          default: ->(_, _) { "y" }
        )
      end

      def copy_spec_support
        create_project_dir("spec")
        copy_files_to_project("support", "spec/")
      end

      def update_config_application
        ConfigApplication.new(cli.app_path).append_to_body(GENERATORS.split("\n"))
      end
    end
  end
end
