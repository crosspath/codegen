# frozen_string_literal: true

module PostInstallSteps
  class RemoveKeeps < PostInstallScript::Step
    def call
      keep_file_path = File.join(@app_path, "vendor/javascript/.keep")
      return unless File.exist?(keep_file_path)

      indent(STEP)
    end

    STEP = <<~RUBY
      section.call("Remove vendor/javascript/.keep...")
      File.unlink("vendor/javascript/.keep") if File.exist?("vendor/javascript/.keep")
      if Dir.empty?("vendor/javascript")
        Dir.delete("vendor/javascript")
        if File.exist?("app/assets/config/manifest.js")
          lines = File.readlines("app/assets/config/manifest.js")
          lines -= ["//= link_tree ../../../vendor/javascript .js\\n"]
          File.write("app/assets/config/manifest.js", lines.join)
        end
      end
    RUBY

    private_constant :STEP
  end
end
