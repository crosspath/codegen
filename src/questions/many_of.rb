# frozen_string_literal: true

module Questions
  class ManyOf < Base
    def call
      show_variants do |variants|
        print "Choose one or more and press Enter -> "
        answer = get_string

        return @default_value if answer.empty?

        keys = answer.chars
        return variants.slice(*keys).map(&:first) if (variants.keys & keys).size == keys.size
      end
    end
  end
end
