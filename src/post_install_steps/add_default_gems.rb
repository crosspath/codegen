# frozen_string_literal: true

module PostInstallSteps
  class AddDefaultGems < PostInstallScript::Step
    def call
      indent(STEP)
    end

    DEFAULT_GEMS = %w[ostruct].freeze

    STEP = <<~RUBY
      section.call("Add default gems (they'll be removed from stdlib in next major Ruby version)...")
      File.open("Gemfile", "a") do |f|
        f << "\\n# Will no longer be part of the default gems starting from Ruby 3.5.0\\n"
        f << #{DEFAULT_GEMS.inspect}.map { |g| "gem \\"\#{g}\\"" }.join("\\n")
      end
    RUBY

    private_constant :DEFAULT_GEMS, :STEP
  end
end
