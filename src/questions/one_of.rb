# frozen_string_literal: true

module Questions
  class OneOf < Base
    def call
      show_variants do |variants|
        print "Choose one -> "
        answer = get_char
        puts

        return @default_value if answer.nil?
        return variants[answer][0] if variants.key?(answer)
      end
    end
  end
end
