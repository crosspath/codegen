class Ask
  Interrupt = Class.new(RuntimeError)

  def initialize(gopt, ropt)
    @gopt = gopt
    @ropt = ropt
  end

  def question(definition)
    case definition[:type]
    when :text
      Ask.line(definition)
    when :boolean
      Ask.yes?(definition)
    when :one_of
      Ask.one_of(definition)
    when :many_of
      Ask.many_of(definition)
    else
      raise ArgumentError, definition[:type].to_s
    end
  end

  def line(definition)
    default_value = default_value_for(definition)
    default_text = default_text_for(default_value)

    loop do
      print definition[:label], default_text, " -> "
      answer = get_string
      answer = default_value if answer.empty?
      return answer if answer

      puts "Unexpected answer!"
    end
  end

  def yes?(definition)
    default_value = default_value_for(definition)
    default_text = default_text_for(default_value)

    loop do
      print definition[:label], default_text, " (y/n) -> "
      answer = get_char || default_value
      puts

      case answer
      when "y" then return true
      when "n" then return false
      end

      puts "Unexpected answer!"
    end
  end

  def one_of(definition)
    default_value = default_value_for(definition)
    default_text = default_text_for(default_value)

    variants = definition[:variants].transform_keys(&:to_s)
    hint = variants.map { |k, v| "#{k} - #{v}" }.join("\n")

    print definition[:label], default_text, "\n", hint, "\n"

    loop do
      print "Choose one -> "
      answer = get_char || default_value
      puts

      return answer if variants.key?(answer)

      puts "Unexpected answer!"
    end
  end

  def many_of(definition)
    default_value = default_value_for(definition)
    default_text = default_text_for(default_value)

    variants = definition[:variants].transform_keys(&:to_s)
    hint = variants.map { |k, v| "#{k} - #{v}" }.join("\n")

    print definition[:label], default_text, "\n", hint, "\n"

    loop do
      print "Choose one or more and press Enter -> "
      answer = get_string
      answer = default_value if answer.empty?
      keys = answer.split("")

      return answer if (variants.keys & keys).size == keys.size

      puts "Unexpected answer!"
    end
  end

  private

  def default_value_for(definition)
    value = definition[:default]&.call(@gopt, @ropt)
    return if value.nil?

    definition[:type] == :boolean ? (value ? "y" : "n") : value
  end

  def default_text_for(value)
    value ? " (default: #{value})" : nil
  end

  def get_string
    Signal.trap('INT') { raise Interrupt } # Ctrl+C
    result = STDIN.gets # nil if Ctrl+D
    raise Interrupt unless result

    result.chomp
  end

  def get_char
    c = STDIN.getch
    raise Interrupt if ["\u0003", "\u0004"].include?(c) # Ctrl+C, Ctrl+D
    print c # Inserted character is hidden by default.
    ["\r", "\n"].include?(c) ? nil : c
  end
end
