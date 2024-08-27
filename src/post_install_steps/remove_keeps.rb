module PostInstallSteps
  class RemoveKeeps < Base
    def call
      keep_file_path = File.join(@app_path, "vendor/javascript/.keep")
      return unless File.exist?(keep_file_path)

      indent(STEP_KEEPS)
    end

    private

    STEP_KEEPS = <<~RUBY
      puts "Remove vendor/javascript/.keep..."
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

    private_constant :STEP_KEEPS
  end
end