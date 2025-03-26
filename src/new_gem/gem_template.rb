# frozen_string_literal: true

require_relative "../erb_eval"

module NewGem
  class GemTemplate
    def initialize(gem_base_file_name:, gem_class_name:, gem_path:, ruby_version:)
      @gem_base_file_name = gem_base_file_name
      @gem_class_name = gem_class_name
      @gem_path = gem_path
      @ruby_version = ruby_version
    end

    def generate
      create_dirs
      copy_files
      create_files_from_templates

      `chmod +x #{@gem_path}/exe/#{@gem_base_file_name} #{@gem_path}/bin/*`
    end

    private

    def copy_files
      copy_files_to_gem(".bundle", "")
      copy_files_to_gem(".gitignore", "")
      copy_files_to_gem("CHANGELOG.md", "")
      copy_files_to_gem("Gemfile", "")
      copy_files_to_gem("bin/rubocop", "bin")
      copy_files_to_gem("bin/yard", "bin")
    end

    # Copy files or directories.
    # @param read_from [String]
    # @param save_to [String]
    # @return [String] Command output
    def copy_files_to_gem(read_from, save_to)
      source = File.join(__dir__, "files", read_from)
      destination = File.join(@gem_path, save_to)

      `cp -r #{source} #{destination}`
    end

    def create_dirs
      create_gem_dir("bin")
      create_gem_dir("exe")
      create_gem_dir("lib/#{@gem_base_file_name}")
    end

    def create_files_from_templates
      erb(".rubocop.yml", ".rubocop.yml", ruby_version: @ruby_version)

      erb(
        "gem.gemspec",
        "#{@gem_base_file_name}.gemspec",
        gem_author: `git config get --global user.name`.strip,
        gem_base_file_name: @gem_base_file_name,
        gem_class_name: @gem_class_name,
        ruby_version: "#{@ruby_version}.0"
      )

      erb(
        "README.md",
        "README.md",
        name: StringUtils.underscores_to_titleize(@gem_base_file_name)
      )

      options = {gem_base_file_name: @gem_base_file_name, gem_class_name: @gem_class_name}

      erb("bin/build", "bin/build", **options)
      erb("bin/release", "bin/release", **options)
      erb("exe/gem", "exe/#{@gem_base_file_name}", **options)
      erb("lib/gem.rb", "lib/#{@gem_base_file_name}.rb", **options)

      erb(
        "lib/gem/version.rb",
        "lib/#{@gem_base_file_name}/version.rb",
        gem_class_name: @gem_class_name
      )
    end

    # @param dir_name [String]
    # @return [Boolean] Operation state ("true" on success)
    def create_gem_dir(dir_name)
      `mkdir -m 0755 -p #{@gem_path}/#{dir_name}`
    end

    # @param read_from [String]
    # @param save_to [String]
    # @param locals [Hash<String, Object>]
    # @return [void]
    def erb(read_from, save_to, **locals)
      file_name = File.join(__dir__, "files", "#{read_from}.erb")
      result = ErbEval.call(File.read(file_name), **locals)
      result += "\n" unless result.end_with?("\n")

      File.write(File.join(@gem_path, save_to), result)
    end
  end
end
