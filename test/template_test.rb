# frozen_string_literal: true

require "minitest/autorun"

# @see https://github.com/excid3/jumpstart/blob/master/test/template_test.rb
class TemplateTest < Minitest::Test
  def setup
    system("[ -d test_app ] && rm -rf test_app")
  end

  def teardown
    setup
  end

  def test_api_6
    run_generator("api_6", "Done!")
  end

  def test_api_7
    run_generator("api_7", "Done!")
  end

  def test_minimal_6
    run_generator("minimal_6", "Done!")
  end

  def test_minimal_7
    run_generator("minimal_7", "Done!")
  end

  def test_full_6
    run_generator("full_6", "Webpacker successfully installed")
  end

  def test_full_7
    run_generator("full_7", "Pin all controllers") # Message from TurboRails
  end

  protected

  def run_generator(name, message)
    file_name = "test/examples/#{name}.txt"

    output, _err =
      capture_subprocess_io { system("DISABLE_SPRING=1 NO_SAVE=1 ./new.rb #{file_name}") }

    assert_includes(output, message)
  end
end
