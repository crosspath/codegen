# frozen_string_literal: true

module Questions
  class Boolean < Base
    def initialize(_definition, _gopt, _ropt)
      super
      default_text = default_text_for(@default_value)
      @prompt = "#{@definition[:label]}#{default_text} (y/n) -> "
    end

    def call
      loop do
        print @prompt
        answer = get_char || @default_value
        puts

        case answer
        when "y" then return true
        when "n" then return false
        end

        puts "Unexpected answer!"
      end
    end
  end
end
