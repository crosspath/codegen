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

      CONFIG_APP_FILE = "config/application.rb"
      RE_TWO_ENDS = /^\s*end\b.*?\s*end\b/m

      GENERATORS = <<~RUBY
        config.generators do |g|
          g.factory_bot(dir: "factories", filename_proc: ->(t) { t.singularize })
        end
      RUBY

      private_constant :GROUP_DEV_TEST, :CONFIG_APP_FILE, :RE_TWO_ENDS, :GENERATORS

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

        if use_rswag
          copy_files_to_project("bin", "")
          cli.post_install_script.add_steps(ConfigurateRswag)
        else
          copy_files_to_project("bin/rspec", "bin/rspec")
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
        create_project_dir("spec/support")
        copy_files_to_project("custom_test_methods.rb", "spec/support/")
      end

      def update_config_application
        file = read_project_file(CONFIG_APP_FILE)
        two_last_ends = file.rindex(RE_TWO_ENDS)
        raise "Cannot find two last `end`s in `#{CONFIG_APP_FILE}` file" unless two_last_ends

        new_lines = StringUtils.indent(GENERATORS.split("\n"), 2)
        file.insert(two_last_ends, "#{new_lines.join("\n")}\n")
        write_project_file(CONFIG_APP_FILE, file)
      end
    end
  end
end
