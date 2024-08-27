# frozen_string_literal: true

require_relative "../../src/post_install_script"

class ConfigurateYard < PostInstallScript::Step
  def call
    indent(STEP)
  end

  private

  STEP = <<~RUBY
    `bin/yard config --gem-install-yri`
  RUBY

  private_constant :STEP
end
