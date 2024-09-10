# frozen_string_literal: true

require_relative "known_tool"
require_relative "tool_registry"

module Features
  module Tools
    class ToolsMain < Feature
      register_as "linters, formatters and documentation tools"

      def call
        require_tools

        gems = application_gems
        registry = Features::Tools::ToolRegistry.all
        tools = initialize_tools(registry, gems)
        use_tools = registry.transform_values(&:selected) # => {brakeman: true, ...}

        if use_tools.values.all?(false)
          puts "Nothing to do!"
          return
        end

        add_tools_to_project(registry, gems, tools, use_tools)
      end

      private

      # @return [nil]
      def require_tools
        Dir.glob("known_tools/*.rb", base: __dir__, sort: true).each { |x| require_relative x }
      end

      # @return [Hash<Symbol, Features::Tools::KnownTool>]
      # Example: {"brakeman" => #<Features::Tools::KnownTools::Brakeman>, ...}
      def initialize_tools(registry, gems)
        registry
          .transform_values { |item| item.klass.new(cli, gems) }
          .each { |key, inst| registry[key].selected = inst.use? }
      end

      def add_tools_to_project(registry, gems, tools, use_tools)
        create_dirs_for_tools(registry, use_tools)
        run_tools(tools, use_tools)
        create_gemfile(gems, use_tools)
        link_bundle_dir
      end

      # @return [nil]
      def create_dirs_for_tools(registry, use_tools)
        add_configs = registry.any? { |_key, item| item.selected && item.adds_config }

        create_project_dir(KnownTool::DIR_CONFIG) if add_configs
        create_project_dir(KnownTool::DIR_HOOKS) if use_tools["overcommit"]
      end

      # @return [Hash<Symbol, Boolean>]
      def run_tools(tools, use_tools)
        use_tools.each { |key, selected| tools[key].call(use_tools) if selected }
      end

      # @return [nil]
      def create_gemfile(gems, use_tools)
        puts "Create Gemfile for directory `#{KnownTool::DIR}`..."

        erb("Gemfile", File.join(KnownTool::DIR, "Gemfile"), **use_tools, gems:)
        write_project_file(File.join(KnownTool::DIR, "Gemfile.lock"), "")
      end

      # @return [nil]
      def link_bundle_dir
        return if !project_file_exist?(".bundle") || project_file_exist?(".tools/.bundle")

        puts "Create link .tools/.bundle -> .bundle..."
        run_command_in_project_dir("ln -s --relative .bundle .tools/")
      end

      # @return [Hash<String, Boolean>]
      def application_gems
        result = GemfileLock.new(cli.app_path).gems

        result << "rswag" if result.include?("rswag-specs")
        result << "rspec" if result.include?("rspec-core")

        result.to_h { |item| [item, true] }
      end
    end
  end
end
