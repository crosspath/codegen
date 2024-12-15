# frozen_string_literal: true

require_relative "erb_eval"
require_relative "feature_registry"

# Base class for actions & changes applied to application directory.
# @abstract
class Feature
  # @param name [String] Title
  # @param before [String, nil] Directory name of another feature
  # @return [void]
  def self.register_as(name, before: nil)
    item = FeatureRegistry.add(self, name, before)

    # Instance-level method
    define_method(:registry_item) { item }
  end

  # @param cli [ChangeProject::CLI]
  def initialize(cli)
    @cli = cli
  end

  # @return [void]
  def call
    raise NotImplementedError
  end

  private

  ROOT_DIR = File.dirname(__dir__).freeze

  private_constant :ROOT_DIR

  attr_reader :cli

  # @return [String]
  def feature_dir
    @feature_dir ||= File.join(ROOT_DIR, "features", registry_item.hash_key)
  end

  # @param read_from [String]
  # @param save_to [String]
  # @param locals [Hash<String, Object>]
  # @return [void]
  def erb(read_from, save_to, **locals)
    file_name = File.join(feature_dir, "files", "#{read_from}.erb")
    result = ErbEval.call(File.read(file_name), **locals)

    write_project_file(save_to, result)
  end

  # @param file_name [String]
  # @return [Boolean]
  def project_file_exist?(file_name)
    File.exist?(File.join(cli.app_path, file_name))
  end

  # @param file_name [String]
  # @return [String]
  def read_project_file(file_name)
    File.read(File.join(cli.app_path, file_name))
  end

  # @param file_name [String]
  # @param result [String]
  # @return [void]
  def write_project_file(file_name, result)
    result += "\n" unless result.end_with?("\n")
    File.write(File.join(cli.app_path, file_name), result)
  end

  # @param file_name [String]
  # @return [void]
  def remove_project_file(file_name)
    File.unlink(File.join(cli.app_path, file_name))
  end

  # @param dir_name [String]
  # @return [Boolean] Operation state ("true" on success)
  def create_project_dir(dir_name)
    run_command_in_project_dir("mkdir -m 0755 -p #{dir_name}")
  end

  # @param dir_name [String]
  # @return [Boolean] Operation state ("true" on success)
  def remove_project_dir(dir_name)
    run_command_in_project_dir("rm -r -f #{dir_name}")
  end

  # @param base [String]
  # @param search_pattern [String]
  # @return [Array<String>]
  def project_files(base, search_pattern)
    Dir.glob(search_pattern, base: File.join(cli.app_path, base))
  end

  # Copy files or directories.
  # @param read_from [String]
  # @param save_to [String]
  # @return [String] Command output
  def copy_files_to_project(read_from, save_to)
    source = File.join(feature_dir, "files", read_from)
    destination = File.join(cli.app_path, save_to)

    `cp -r #{source} #{destination}`
  end

  # @param file_name [String]
  # @param add [Array<String>]
  # @param delete [Array<String>]
  # @return [void]
  def update_ignore_file(file_name, add: [], delete: [])
    entries = project_file_exist?(file_name) ? read_project_file(file_name).split("\n") : []
    entries.reject! { |line| line.empty? || line.start_with?("#") }

    entries = entries + add - delete
    entries = Set.new(entries).to_a.sort_by { |line| line.gsub(%r{!|/}, "") } + [""]

    write_project_file(file_name, entries.join("\n"))
  end

  # @param gems [Array<String>]
  # @param kwargs [Hash<Symbol, Object>]
  # @option :group [String, Symbol, Array<String | Symbol>]
  #   If `:test` then ", group: :test". If `[:test]` then ", group: [:test]".
  # @return [void]
  def add_gem(*gems, **kwargs)
    gem_params = kwargs.map { |k, v| ", #{k}: #{v.inspect}" }.join
    new_gems = gems.map { |name| "gem \"#{name}\"#{gem_params}" }.join("\n")
    gemfile = "#{read_project_file("Gemfile")}\n#{new_gems}\n"
    write_project_file("Gemfile", gemfile)
  end

  # @param cmd [String]
  # @return [Boolean] Operation state ("true" on success)
  def run_command_in_project_dir(cmd)
    system("cd #{cli.app_path} && #{cmd}")
  end
end
