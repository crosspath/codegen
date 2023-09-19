#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./change.rb
# ./change.rb project-directory
# ./change.rb project-directory feature-name
# ./change.rb project-directory feature-1 feature-2 feature-3 ...

require "erubi"
require "io/console"
require_relative "src/ask"

FEATURES = {
  docker: {},
  yarn: {},
}

class CLI
  def initialize(argv)
    @app_path = argv.shift
    @features = argv.map(&:to_sym)
    @ask = Ask.new({}, {})

    not_supported_features = @features - FEATURES.keys
    raise ArgumentError, not_supported_features.join(", ") unless not_supported_features.empty?
  end

  def call
    @app_path = @ask.line(label: "Application path") if @app_path.nil? || @app_path.empty?
    @app_path = File.expand_path(@app_path, __dir__)

    @features.each do |feature|
      # todo... call methods
    end
  end

  private

  def add_docker
    locals = {
      ruby_version: read_project_file(".ruby-version").strip,
      bundler_version: read_project_file("Gemfile.lock").match(/\nBUNDLED WITH\n\s*(\S+)/)[1],
      yarn_version: read_project_file("package.json").match(/\n  "packageManager": "yarn@([\w.-]+)"/)[1],
    }
    erb(feature, "Dockerfile", "", **locals)
  end

  def add_yarn
    # @see https://yarnpkg.com/getting-started/install
    # @see https://nodejs.org/api/corepack.html
    res = `corepack enable`
    if res.include?("permission denied")
      puts "Corepack (part of NPM) requires sudo privileges for creating symlinks."
      raise "Cannot enable Corepack that is required for Yarn." unless system("sudo corepack enable")
    end

    puts "Installing the latest stable version of Yarn..."
    raise "Installation failed" unless system("yarn set version stable")

    puts "Add \"packageManager\" entry to \"package.json\"..."
    version = `cd #{@app_path} && yarn --version`
    system("npm pkg set packageManager=yarn@#{version}")

    if @ask.yes?(label: "Use Plug'n'Play in Yarn - it should not be used with React Native", default: ->(_, _) { "y" })
      yarnrc_yml_changes = {}

      # @see https://yarnpkg.com/migration/pnp#enabling-yarn-pnp
      yarnrc_yml_changes["nodeLinker"] = "pnp"

      # @see https://yarnpkg.com/advanced/lexicon#local-cache
      # @see https://yarnpkg.com/features/caching#zero-installs
      # Not recommended for projects with many dependencies.
      if @ask.yes?(label: "Use Zero-installs - store packages (.yarn/cache) in project repo", default: ->(_, _) { "n" })
        yarnrc_yml_changes["enableGlobalCache"] = "false"
        puts warning(
          "You may be interested in using git submodule for .yarn/cache directory. See more:\n"
          "https://github.com/yarnpkg/berry/discussions/4845#discussioncomment-3637094"
        )
      end

      puts "Update .yarnrc.yml file..."
      yarnrc_yml = update_yarnrc_yml(add: yarnrc_yml_changes)

      # @see https://yarnpkg.com/getting-started/qa#which-files-should-be-gitignored
      puts "Update .gitignore file..."
      update_gitignore(yarnrc_yml)

      # @see https://yarnpkg.com/getting-started/editor-sdks#tools-currently-supported
      puts "Add Yarn Plug'n'Play support to VS Code..."
      system("yarn dlx @yarnpkg/sdks vscode")
    else
      update_yarnrc_yml(add: {"nodeLinker" => "node-modules"})
    end

    puts "Download front-end packages for your application..."
    system("yarn install")
  end

  def update_yarnrc_yml(add: {})
    lines = project_file_exist?(".yarnrc.yml") ? read_project_file(".yarnrc.yml").split("\n") : []

    lines.each_with_index do |line, index|
      # Replace options in-line.
      add.each do |key, value|
        if line.begin_with?("#{key}:")
          lines[index] = "#{key}: #{value}"
          add.delete(key)
        end
      end
    end

    # Append missing options.
    add.each do |key, value|
      lines << "#{key}: #{value}"
    end

    # Keep blank line at the end of file.
    lines.reject!(&:empty?)
    lines << ""

    write_project_file(".yarnrc.yml", lines.join("\n"))

    lines.to_h { |line| line.split(":", 2).map(&:strip) }
  end

  def update_gitignore(yarnrc_yml)
    entries = []

    if yarnrc_yml["enableGlobalCache"] == "false"
      entries << "!.yarn/cache"
    else
      entries << ".pnp.*"
    end

    entries << ".yarn/*"
    entries << "!.yarn/patches"
    entries << "!.yarn/sdks"
    entries << "!.yarn/versions"

    gitignore = project_file_exist?(".gitignore") ? read_project_file(".gitignore").split("\n") : []
    gitignore.reject! { |line| line.empty? || line.begin_with?("#") }
    gitignore = Set.new(gitignore + entries).to_a.sort

    write_project_file(".gitignore", gitignore.join("\n"))
  end

  def warning(text)
    lines = text.split("\n")
    length = lines.map(&:size).max

    puts
    puts("=" * length)
    puts text
    puts("-" * length)
    puts
  end

  def erb(feature, read_from, save_to, **locals)
    b = binding
    locals.each { |k, v| b.local_variable_set(k, v) }

    file_name = File.join(__dir__, "features", feature, "#{read_from}.erb")
    result = b.eval(Erubi::Engine.new(File.read(file_name)).src)

    write_project_file(save_to, result)
  end

  def project_file_exist?(file_name)
    File.exist?(File.join(@app_path, file_name))
  end

  def read_project_file(file_name)
    File.read(File.join(@app_path, file_name))
  end

  def write_project_file(file_name, result)
    File.write(File.join(@app_path, file_name), result)
  end
end

CLI.new(ARGV.dup).call
