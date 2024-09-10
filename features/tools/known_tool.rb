# frozen_string_literal: true

module Features
  module Tools
    # @abstract
    class KnownTool < Feature
      DIR = ".tools"
      DIR_BIN = "bin"
      DIR_CONFIG = "#{DIR}/config".freeze
      DIR_HOOKS = "#{DIR}/hooks".freeze

      # @param name [String] Visible text in CLI
      # @param adds_config [Boolean]
      def self.register_as(name, adds_config: false)
        item = Features::Tools::ToolRegistry.add(self, name, adds_config)

        # Instance-level method
        define_method(:registry_item) { item }
      end

      # @param cli [ChangeProject::CLI]
      # @param gems [Hash<String, Boolean>]
      def initialize(cli, gems)
        super(cli)

        @gems = gems
      end

      # @return [Boolean]
      def use?
        cli.ask.question(
          type: :boolean,
          label: "Use #{registry_item.name}",
          default: ->(_, _) { "y" }
        )
      end

      private

      # @return [String]
      def feature_dir
        @feature_dir ||= File.join(ROOT_DIR, "features", "tools")
      end

      def add_gem_for_development(name)
        puts "Add gem #{name}..."
        add_gem(name, group: :development)
      end
    end
  end
end
