# frozen_string_literal: true

module Features
  class Crud < Feature
    register_as "default CRUD actions"

    def call
      puts "Add gems..."
      add_gem("blueprinter")

      puts "Copy files..."
      copy_files_to_project("crud_actions.rb", "app/controllers/concerns")

      puts "Add example route..."
      update_config_routes

      puts "Add mixin to ApplicationController..."
      update_application_controller

      puts "Apply configuration..."
      add_inflections
    end

    private

    ROUTES_FILE = "config/routes.rb"
    RE_END = /\A\s*end\b/

    EXAMPLE_ROUTE = <<~RUBY
      namespace :api do
        with_options only: %i[create destroy index show update] do
          resources :authors
        end
      end
    RUBY

    CONTROLLER_FILE = "app/controllers/application_controller.rb"
    RE_CONTROLLER = /\A\s*class\s*ApplicationController\s*</
    MIXIN = "include CrudActions"

    INFLECTIONS_FILE = "config/initializers/inflections.rb"
    INFLECTIONS_EXAMPLE = <<~RUBY
      ActiveSupport::Inflector.inflections(:en) { |inflect| inflect.acronym("API") }
    RUBY

    private_constant :ROUTES_FILE, :RE_END, :EXAMPLE_ROUTE, :CONTROLLER_FILE, :RE_CONTROLLER, :MIXIN
    private_constant :INFLECTIONS_FILE, :INFLECTIONS_EXAMPLE

    def update_config_routes
      assert_file_exists(ROUTES_FILE)
      lines = read_project_file(ROUTES_FILE).split("\n")
      last_line_with_end = lines.rindex { |line| line =~ RE_END }
      raise "Cannot find last `end` in `#{ROUTES_FILE}` file" unless last_line_with_end

      lines.insert(last_line_with_end, *indent(EXAMPLE_ROUTE.split("\n")))
      write_project_file(ROUTES_FILE, lines.join("\n"))
    end

    def update_application_controller
      assert_file_exists(CONTROLLER_FILE)
      lines = read_project_file(CONTROLLER_FILE).split("\n")
      start_class_line = lines.index { |line| line =~ RE_CONTROLLER }
      raise "Cannot find class definition in `#{CONTROLLER_FILE}` file" unless start_class_line

      lines.insert(start_class_line + 1, indent([MIXIN]))
      write_project_file(CONTROLLER_FILE, lines.join("\n"))
    end

    def add_inflections
      file = read_project_file(INFLECTIONS_FILE)
      write_project_file(INFLECTIONS_FILE, "#{file}\n#{INFLECTIONS_EXAMPLE}")
    end

    def assert_file_exists(file_name)
      raise "File does not exist: #{file_name}" unless project_file_exist?(file_name)
    end
  end
end
