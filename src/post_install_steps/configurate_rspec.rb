module PostInstallSteps
  class ConfigurateRspec < Base
    def call
      indent(STEP)
    end
  end

  private

  STEP = <<~RUBY
    puts "Add RSpec..."
    `bin/rails g rspec:install`
    lines = File.read("#{RAILS_HELPER_FILE}").split("\n")
    # Get first line that meets any one of these criterions:
    # a) Empty line
    # b) `RSpec.configure`
    index = lines.index { |line| line =~ #{RE_LINE_FOR_REQUIRES} }
    unless index
      raise "Cannot find empty line nor `RSpec.configure` block in `#{RAILS_HELPER_FILE}` file"
    end
    lines.insert(index, %(require_relative "support/custom_test_methods"\n))
    # Find last `end` - it should match `RSpec.configure` block.
    last_line_with_end = lines.rindex { |line| line =~ #{RE_END} }
    raise "Cannot find last `end` in `#{RAILS_HELPER_FILE}` file" unless last_line_with_end
    lines.insert(last_line_with_end, "", #{indent(INCLUDES).inspect})
    File.write("#{RAILS_HELPER_FILE}", lines.join("\n"))
  RUBY

  RAILS_HELPER_FILE = "spec/rails_helper.rb"
  RE_LINE_FOR_REQUIRES = /^$|^\s*RSpec\.configure\b/

  INCLUDES = <<~RUBY
    config.include(FactoryBot::Syntax::Methods)
    config.include(CustomTestMethods)
  RUBY
  RE_END = /\A\s*end\b/

  private_constant :STEP, :RAILS_HELPER_FILE, :RE_LINE_FOR_REQUIRES, :INCLUDES, :RE_END
end
