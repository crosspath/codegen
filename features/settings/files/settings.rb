# frozen_string_literal: true

require "json"
require "psych"

module Settings
  class Configurator
    attr_reader :values

    def initialize
      @values = {}
    end

    # @param search_pattern String
    def files(search_pattern)
      Dir.glob(search_pattern, base: Rails.root).each { |f| file(f) }
    end

    # @param file_name String
    def file(file_name)
      file_path = Rails.root.join(file_name).to_s

      hash =
        case File.extname(file_name)
        when ".json" then JSON.load_file(file_path, symbolize_names: true)
        when ".yaml", ".yml" then Psych.safe_load_file(file_path, symbolize_names: true)
        else
          raise ArgumentError, "Unsupported file extension: #{file_name}"
        end

      raise ArgumentError, "File #{file_name} is empty" if hash.blank?

      @values.merge!(hash)
    end
  end

  extend self

  # @returns Struct-like object
  def configurate(&)
    conf = Configurator.new
    conf.instance_eval(&)

    @struct_cache = {}
    @struct_methods = Struct.instance_methods | Struct.private_instance_methods
    generate_struct(conf.values)
  end

  private

  def generate_struct(value)
    case value
    when Numeric, String, TrueClass, FalseClass, NilClass, Range, Date, Time
      value
    when Array
      value.map { |v| generate_struct(v) }
    when Hash
      hash_to_struct(value)
    else
      raise ArgumentError, "Unknown class: #{value.class.name}"
    end
  end

  def hash_to_struct(value)
    value = value.to_h { |k, v| [k.to_sym, generate_struct(v)] }
    keys = value.keys.sort
    matches_with_base_methods = keys & @struct_methods

    unless matches_with_base_methods.empty?
      error_keys = matches_with_base_methods.join(", ")
      raise ArgumentError, "These keys should not be present in settings file: #{error_keys}"
    end

    @struct_cache[keys] ||= Struct.new(*keys, keyword_init: true)
    @struct_cache[keys].new(value)
  end
end
