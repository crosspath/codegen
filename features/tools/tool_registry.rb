# frozen_string_literal: true

require_relative "../../src/registry"

module Features::Tools
  # Singleton-like registry for tools list.
  class ToolRegistry < Registry
    RegistryItem = Struct.new(:klass, :name, :adds_config, :selected, :hash_key)

    @instance = new

    # @param klass [Class]
    # @param name [String] Visible text in CLI
    # @param adds_config [Boolean]
    # @return [RegistryItem]
    def self.add(klass, name, adds_config)
      hash_key = tool_name(klass.name)
      item = RegistryItem.new(klass, name, adds_config, false, hash_key)
      instance_variable_get(:@instance).add(item)

      item
    end

    def self.all
      @instance.all
    end

    # @param class_name [String]
    # @return [String]
    def self.tool_name(class_name)
      res =
        class_name
          .match(/::([^:]+)$/)[1]
          .gsub(/[A-Z][a-z\d]/) { |x| "_#{x.downcase}" }
          .gsub(/[A-Z]+/) { |x| "_#{x.downcase}" }

      res[1..]
    end
  end
end
