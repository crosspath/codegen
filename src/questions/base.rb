# frozen_string_literal: true

module Questions
  class Base
    Interrupt = Class.new(RuntimeError).freeze

    def initialize(definition, gopt, ropt)
      @definition = definition
      @gopt = gopt
      @ropt = ropt
      @default_value = default_value_for(definition)
    end

    private

    KEYS = (("1".."9").to_a + ("a".."z").to_a).freeze

    private_constant :KEYS

    def default_value_for(definition)
      value = definition[:default]&.call(@gopt, @ropt)
      return if value.nil?
      return (value ? "y" : "n") if definition[:type] == :boolean

      value
    end

    def default_text_for(value, variants = nil)
      if variants
        value =
          variants
            .filter_map { |vis_key, (stor_key, _title)| vis_key if value.include?(stor_key) }
            .join(", ")
      end
      value ? " (default: #{value})" : nil
    end

    # => {"1" => ["stored-key", "visible title"], ...}
    def variants_for_definition(definition)
      KEYS.take(definition[:variants].size).zip(definition[:variants]).to_h
    end

    def hint_for_variants(variants)
      variants.map { |k, (_, v)| "#{k} - #{v}" }.join("\n")
    end

    def get_string # rubocop:disable Naming/AccessorMethodName
      Signal.trap("INT") { raise Interrupt } # Ctrl+C
      result = $stdin.gets # nil if Ctrl+D
      raise Interrupt unless result

      result.chomp
    end

    def get_char # rubocop:disable Naming/AccessorMethodName
      c = $stdin.getch
      raise Interrupt if ["\u0003", "\u0004"].include?(c) # Ctrl+C, Ctrl+D

      print c # Inserted character is hidden by default.
      ["\r", "\n"].include?(c) ? nil : c
    end

    def show_variants
      variants = variants_for_definition(@definition)
      hint = hint_for_variants(variants)

      default_text = default_text_for([@default_value], variants)

      print @definition[:label], default_text, "\n", hint, "\n"

      loop do
        yield(variants) # Should use `return` to exit from loop.
        puts "Unexpected answer!"
      end
    end
  end
end
