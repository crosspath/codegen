# frozen_string_literal: true

require_relative "registry"

# Singleton-like registry for features list.
class FeatureRegistry < Registry
  # Element of {FeatureRegistry}.
  RegistryItem = Struct.new(:klass, :name, :hash_key)

  @instance = new

  # @param klass [Class]
  # @param name [String] Visible text in CLI
  # @param before [String, nil]
  # @return [RegistryItem]
  def self.add(klass, name, before)
    item = RegistryItem.new(klass, name, feature_dir(klass.name))
    @instance.add(item, before)

    item
  end

  # (see Registry.all)
  def self.all
    @instance.all
  end

  # @param class_name [String]
  # @return [String]
  def self.feature_dir(class_name)
    res =
      class_name
        .match(/^Features::([^:]+)/)[1]
        .gsub(/[A-Z][a-z\d]/) { |x| "-#{x.downcase}" }
        .gsub(/[A-Z]+/) { |x| "-#{x.downcase}" }

    res[1..]
  end
end
