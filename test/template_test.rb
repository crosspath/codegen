# frozen_string_literal: true

require "minitest/autorun"

# @see https://github.com/excid3/jumpstart/blob/master/test/template_test.rb
class TemplateTest < Minitest::Test
  TEST_DIRS = %w[
    api_7
    full_7
    minimal_7
  ].freeze

  def setup
    TEST_DIRS.each do |dir|
      system("[ -d tmp/#{dir} ] && rm -rf tmp/#{dir}")
    end
  end

  def teardown
    setup
  end

  def test_api_7
    run_generator("api_7", "Done!")
  end

  def test_minimal_7
    run_generator("minimal_7", "Done!")
  end

  def test_full_7
    run_generator("full_7", "Pin all controllers") # Message from TurboRails
  end

  protected

  def run_generator(name, message)
    puts "", "Generating #{name}..."
    file_name = "test/examples/#{name}.yaml"

    output, _err = capture_subprocess_io { system("NO_SAVE=1 ./new.rb #{file_name}") }

    assert_includes(output, message)
  end
end
