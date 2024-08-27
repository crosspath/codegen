# frozen_string_literal: true

module Features
  class Testing < Feature
    register_as "testing tools"

    def call
      use_rswag = add_rswag?

      puts "Add gems to Gemfile..."
      add_gems_for_testing(use_rswag)

      puts "Copy configuration files..."
      copy_configuration_files(use_rswag)

      puts "Apply configuration..."
      update_config_application
      update_rails_helper
    end

    private

    GROUP_DEV_TEST = %i[development test].freeze

    CMD_RSPEC = "bin/rails g rspec:install"
    CMD_RSWAG = [
      "bin/rails g rswag:api:install",
      "bin/rails g rswag:ui:install",
      "RAILS_ENV=test bin/rails g rswag:specs:install",
      "sed -i s/https:/http:/ spec/swagger_helper.rb",
      "sed -i s/www\\.example\\.com/localhost:3000/ spec/swagger_helper.rb",
    ].join("\n").freeze

    CONFIG_APP_FILE = "config/application.rb"
    RE_TWO_ENDS = /^\s*end\b.*?\s*end\b/m

    GENERATORS = <<~RUBY
      config.generators do |g|
        g.factory_bot(dir: "factories", filename_proc: ->(t) { t.singularize })
      end
    RUBY

    RAILS_HELPER_FILE = "spec/rails_helper.rb"
    RAILS_HELPER_REQUIRES = <<~RUBY
      require_relative "support/custom_test_methods"
    RUBY
    RAILS_HELPER_INCLUDES = <<~RUBY
      config.include(FactoryBot::Syntax::Methods)
      config.include(CustomTestMethods)
    RUBY
    RE_LINE_FOR_REQUIRES_WITHIN_RAILS_HELPER = /^$|^\s*RSpec\.configure\b/
    RE_END = /\A\s*end\b/

    private_constant :GROUP_DEV_TEST, :CMD_RSPEC, :CMD_RSWAG, :CONFIG_APP_FILE, :RE_TWO_ENDS
    private_constant :GENERATORS, :RAILS_HELPER_FILE, :RAILS_HELPER_REQUIRES, :RAILS_HELPER_INCLUDES
    private_constant :RE_LINE_FOR_REQUIRES_WITHIN_RAILS_HELPER, :RE_END

    def add_gems_for_testing(use_rswag)
      if use_rswag
        add_gem("rswag-api", "rswag-ui")
        add_gem("factory_bot_rails", "rspec-rails", "rswag-specs", group: GROUP_DEV_TEST)
      else
        add_gem("factory_bot_rails", "rspec-rails", group: GROUP_DEV_TEST)
      end
    end

    def copy_configuration_files(use_rswag)
      if use_rswag
        copy_files_to_project("bin", "bin")
        warning("Run these lines after `bundle install`:\n#{CMD_RSPEC}\n#{CMD_RSWAG}")
      else
        copy_files_to_project("bin/rspec", "bin/rspec")
        warning("Run this line after `bundle install`:\n#{CMD_RSPEC}")
      end

      copy_spec_support
    end

    def add_rswag?
      cli.ask.question(type: :boolean, label: "Add rswag (OpenAPI 3.0+)", default: ->(_, _) { "y" })
    end

    def copy_spec_support
      create_project_dir("spec/support")
      copy_files_to_project("custom_test_methods.rb", "spec/support/custom_test_methods.rb")
    end

    def update_config_application
      file = read_project_file(CONFIG_APP_FILE)
      two_last_ends = file.rindex(RE_TWO_ENDS)
      raise "Cannot find two last `end`s in `#{CONFIG_APP_FILE}` file" unless two_last_ends

      file.insert(two_last_ends, indent(GENERATORS.split("\n"), 2).join("\n"))
      write_project_file(CONFIG_APP_FILE, file)
    end

    def update_rails_helper
      lines = read_project_file(RAILS_HELPER_FILE).split("\n")

      # Get first line that meets any one of these criterions:
      # a) Empty line
      # b) `RSpec.configure`
      index = lines.index { |line| line =~ RE_LINE_FOR_REQUIRES_WITHIN_RAILS_HELPER }
      unless index
        raise "Cannot find empty line nor `RSpec.configure` block in `#{RAILS_HELPER_FILE}` file"
      end

      lines.insert(index, RAILS_HELPER_REQUIRES)

      # Find last `end` - it should match `RSpec.configure` block.
      last_line_with_end = lines.rindex { |line| line =~ RE_END }
      raise "Cannot find last `end` in `#{RAILS_HELPER_FILE}` file" unless last_line_with_end

      lines.insert(last_line_with_end, "", *indent(RAILS_HELPER_INCLUDES.split("\n")))

      write_project_file(RAILS_HELPER_FILE, lines.join("\n"))
    end
  end
end
