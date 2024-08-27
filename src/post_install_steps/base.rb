module PostInstallSteps
  class Base
    def initialize(app_path)
      @app_path = app_path
    end

    private

    def indent(code)
      "  #{code.split("\n").join("\n  ")}"
    end
  end
end
