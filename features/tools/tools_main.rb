# frozen_string_literal: true

require_relative "known_tool"
require_relative "tool_registry"

module Features
  module Tools
    class ToolsMain < Feature
      register_as "linters, formatters and documentation tools"

      def call
        Dir.glob("known_tools/*.rb", base: __dir__, sort: true).each { |x| require_relative x }

        gems = application_gems
        registry = Features::Tools::ToolRegistry.all

        # => {"brakeman" => #<Features::Tools::KnownTools::Brakeman>, ...}
        tools = registry.transform_values { |item| item.klass.new(cli, gems) }

        tools.each { |key, inst| registry[key].selected = inst.use? }

        # => {brakeman: true, ...}
        use_tools = registry.transform_values(&:selected)

        if use_tools.values.all?(false)
          puts "Nothing to do!"
          return
        end

        add_configs = registry.any? { |_key, item| item.selected && item.adds_config }

        create_project_dir(KnownTool::DIR_CONFIG) if add_configs
        create_project_dir(KnownTool::DIR_HOOKS) if use_tools["overcommit"]

        use_tools.each { |key, selected| tools[key].call(use_tools) if selected }

        puts "Create Gemfile for directory `#{KnownTool::DIR}`..."

        erb("Gemfile", File.join(KnownTool::DIR, "Gemfile"), **use_tools, gems:)
      end

      private

      # @return [Hash<String, Boolean>]
      def application_gems
        gemfile_lock = read_project_file("Gemfile.lock").split("\n")
        lines = gemfile_lock
        result = []

        loop do
          # +1 means "skip lines 'GEM', 'remote', 'specs'"
          gem_list_index = lines.find_index { |line| line == "GEM" }&.+(3)
          break unless gem_list_index

          lines = lines[gem_list_index..]
          result += lines.take_while { |line| !line.empty? }
        end

        raise "Cannot find 'GEM' section in Gemfile.lock" if result.empty?

        result.map! { |line| line[/\S+/] }
        result.to_h { |item| [item, true] }
      end
    end
  end
end
