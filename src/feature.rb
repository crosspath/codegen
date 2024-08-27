# frozen_string_literal: true

require_relative "erb_eval"
require_relative "feature_registry"

class Feature
  def self.register_as(name, before: nil)
    item = FeatureRegistry.add(self, name, before)

    # Instance-level method
    define_method(:registry_item) { item }
  end

  def initialize(cli)
    @cli = cli
  end

  def call
    raise NotImplementedError
  end

  private

  # rubocop:disable Layout/ClassStructure Keep constants in private section to show that they're
  # not intended to be used outside of this file.
  ROOT_DIR = File.dirname(__dir__).freeze
  # rubocop:enable Layout/ClassStructure

  attr_reader :cli

  def warning(text)
    lines = text.split("\n")
    length = lines.map(&:size).max

    puts
    puts("=" * length)
    puts text
    puts("-" * length)
    puts
  end

  def feature_dir
    @feature_dir ||= File.join(ROOT_DIR, "features", registry_item.hash_key)
  end

  def erb(read_from, save_to, **locals)
    file_name = File.join(feature_dir, "files", "#{read_from}.erb")
    result = ErbEval.call(File.read(file_name), **locals)

    write_project_file(save_to, result)
  end

  def project_file_exist?(file_name)
    File.exist?(File.join(cli.app_path, file_name))
  end

  def read_project_file(file_name)
    File.read(File.join(cli.app_path, file_name))
  end

  def write_project_file(file_name, result)
    result += "\n" unless result.end_with?("\n")
    File.write(File.join(cli.app_path, file_name), result)
  end

  def remove_project_file(file_name)
    File.unlink(File.join(cli.app_path, file_name))
  end

  def create_project_dir(dir_name)
    run_command_in_project_dir("mkdir -m 0755 -p #{dir_name}")
  end

  def remove_project_dir(dir_name)
    run_command_in_project_dir("rm -r -f #{dir_name}")
  end

  def project_files(base, search_pattern)
    Dir.glob(search_pattern, base: File.join(cli.app_path, base))
  end

  # Copy files or directories.
  def copy_files_to_project(read_from, save_to)
    source = File.join(feature_dir, "files", read_from)
    destination = File.join(cli.app_path, save_to)

    `cp -r #{source} #{destination}`
  end

  def update_ignore_file(file_name, add: [], delete: [])
    entries = project_file_exist?(file_name) ? read_project_file(file_name).split("\n") : []
    entries.reject! { |line| line.empty? || line.start_with?("#") }

    entries = entries + add - delete
    entries = Set.new(entries).to_a.sort_by { |line| line.gsub(%r{!|/}, "") } + [""]

    write_project_file(file_name, entries.join("\n"))
  end

  def add_gem(*gems, group: nil)
    # If `:test` then ", group: :test". If `[:test]` then ", group: [:test}".
    group = group ? ", group: #{group.inspect}" : ""
    new_gems = gems.map { |name| "gem \"#{name}\"#{group}" }.join("\n")
    gemfile = "#{read_project_file("Gemfile")}\n#{new_gems}\n"
    write_project_file("Gemfile", gemfile)
  end

  def run_command_in_project_dir(cmd)
    system("cd #{cli.app_path} && #{cmd}")
  end

  def indent(lines, level = 1)
    spaces = " " * (2 * level)
    lines.map { |x| x.empty? ? x : "#{spaces}#{x}" }
  end
end
