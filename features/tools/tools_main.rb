# frozen_string_literal: true

require_relative "known_tool"
require_relative "tool_registry"

module Features::Tools
  class ToolsMain < Feature
    register_as "linters, formatters and documentation tools"

    def call
      Dir.glob("known_tools/*.rb", base: __dir__, sort: true).each { |x| require_relative x }

      gems = application_gems
      registry = Features::Tools::ToolRegistry.all
      tools = registry.to_h { |key, item| [key, item.klass.new(cli, gems)] }

      tools.each { |key, inst| registry[key].selected = inst.use? }

      use_tools = registry.to_h { |key, item| [key.to_sym, item.selected] }

      if use_tools.values.all?(false)
        puts "Nothing to do!"
        return
      end

      add_configs = registry.any? { |_key, item| item.selected && item.adds_config }

      run_command_in_project_dir("mkdir -m 0755 -p #{DIR_CONFIG}") if add_configs
      run_command_in_project_dir("mkdir -m 0755 -p #{DIR_HOOKS}") if use_tools[:overcommit]

      use_tools.each_key { |key| tools[key].call }

      puts "Create Gemfile for directory `#{KnownTool::DIR}`..."

      erb("Gemfile", File.join(KnownTool::DIR, "Gemfile"), **use_tools, **gems)
    end

    private

    # @return [Set<String>]
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
      result.to_set
    end
  end
end
