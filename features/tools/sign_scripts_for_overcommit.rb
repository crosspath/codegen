# frozen_string_literal: true

require_relative "../../src/post_install_script"

class SignScriptsForOvercommit < PostInstallScript::Step
  def self.with_options(options)
    klass = Class.new(self)
    klass.define_method(:options) { options }
    klass
  end

  def call
    indent(STEP)
  end

  def options
    {}
  end

  private

  STEP = <<~RUBY
    puts "Sign scripts for Overcommit..."
    `bin/overcommit --sign`
    `bin/overcommit --sign pre-commit`
    #{options[:post_checkout] ? "`bin/overcommit --sign post-checkout`" : ""}
    #{options[:post_commit] ? "`bin/overcommit --sign post-commit`" : ""}
  RUBY

  private_constant :STEP
end
