# frozen_string_literal: true

require "erubi"

class Feature
  module Registry
    extend self

    attr_reader :all

    def init
      @all = []
    end

    def add(klass, feature_name, before = nil)
      item = {klass:, feature_name:}

      if before
        index = @all.find_index { |h| h[:feature_name] == before }
        return @all.insert(index, item) if index
      end

      @all << item
    end
  end

  Feature::Registry.init

  class << self
    def all
      Feature::Registry.all.to_h { |item| [item[:feature_name], item[:klass]] }
    end

    def register_as(feature_name, before: nil)
      Feature::Registry.add(self, feature_name, before)

      # Instance-level method
      define_method(:feature_name) { feature_name }

      # Class-level method
      define_singleton_method(:feature_name) { feature_name }
    end
  end

  def initialize(cli)
    @cli = cli
  end

  def call
    raise NotImplementedError
  end

  protected

  ROOT_DIR = File.dirname(__dir__)

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
    @feature_dir ||= File.join(ROOT_DIR, "features", feature_name)
  end

  def erb(read_from, save_to, **locals)
    b = binding
    locals.each { |k, v| b.local_variable_set(k, v) }

    file_name = File.join(feature_dir, "files", "#{read_from}.erb")
    result = b.eval(Erubi::Engine.new(File.read(file_name), trim_mode: "%<>").src)

    write_project_file(save_to, result)
  end

  def project_file_exist?(file_name)
    File.exist?(File.join(cli.app_path, file_name))
  end

  def read_project_file(file_name)
    File.read(File.join(cli.app_path, file_name))
  end

  def write_project_file(file_name, result)
    File.write(File.join(cli.app_path, file_name), result)
  end

  def remove_project_file(file_name)
    File.unlink(File.join(cli.app_path, file_name))
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

  def run_command_in_project_dir(cmd)
    system("cd #{cli.app_path} && #{cmd}")
  end

  def indent(lines, level = 1)
    spaces = " " * (2 * level)
    lines.map { |x| "#{spaces}#{x}" }
  end
end
