# frozen_string_literal: true

require "minitest/autorun"

# @see https://github.com/excid3/jumpstart/blob/master/test/template_test.rb
class TemplateTest < Minitest::Test
  ITEMS = %w[
    api_7
    api_8
    full_7
    full_8
    minimal_7
    minimal_8
  ].freeze

  def setup
    ITEMS.each { |dir| system("[ -d tmp/#{dir} ] && rm -rf tmp/#{dir}") }
  end

  def teardown
    setup
  end

  ITEMS.each do |name|
    define_method(:"test_#{name}") { run_generator(name) }
  end

  protected

  def run_generator(name)
    puts "", "Generating #{name}..."
    file_name = "test/examples/#{name}.yaml"

    output, _err = capture_subprocess_io { system("TESTING=1 ./new-rails-project.rb #{file_name}") }

    assert_includes(output, "Done!")
  end
end
