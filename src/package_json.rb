# frozen_string_literal: true

# Helper class for reading `package.json` file.
class PackageJson
  # @param dir [String]
  def initialize(dir)
    file_path = File.join(dir, "package.json")
    @lines = File.exist?(file_path) ? JSON.parse(File.read(file_path)) : nil
  end

  # @return [Boolean]
  def exist?
    !@lines.nil?
  end

  # @return [String]
  def package_manager
    @lines["packageManager"]
  end
end
