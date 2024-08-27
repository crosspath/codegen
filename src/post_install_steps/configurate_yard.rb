module PostInstallSteps
  class ConfigurateYard < Base
    def call
      indent(STEP)
    end

    private

    STEP = <<~RUBY
      `bin/yard config --gem-install-yri`
    RUBY

    private_constant :STEP
  end
end
