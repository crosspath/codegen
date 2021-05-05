require "minitest/autorun"

# @see https://github.com/excid3/jumpstart/blob/master/test/template_test.rb
class TemplateTest < Minitest::Test
  def setup
    system("[ -d test_app ] && rm -rf test_app")
  end

  def teardown
    setup
  end

  def test_minimum
    run_generator('minimum', 'Webpacker successfully installed')
  end

  def test_default
    run_generator('default', 'Sorcery installed')
  end

  protected

  def run_generator(name, message)
    output, err = capture_subprocess_io do
      system("DISABLE_SPRING=1 rails new test_app --rc=#{name}.rc --template=codegen.rb")
    end
    assert_includes output, message
  end
end
