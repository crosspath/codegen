# frozen_string_literal: true

module Questions
  class Text < Base
    def initialize(_definition, _gopt, _ropt)
      super
      default_text = default_text_for(@default_value)
      @prompt = "#{@definition[:label]}#{default_text} -> "
    end

    def call
      loop do
        print @prompt
        answer = get_string
        answer = @default_value if answer.empty?
        return answer if answer

        puts "Unexpected answer!"
      end
    end
  end
end
