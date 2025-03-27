# frozen_string_literal: true

require "English" # $CHILD_STATUS

module Features
  class Yarn < Feature
    register_as "yarn", before: "docker"

    def call
      use_plug_and_play = use_plug_and_play?

      enable_corepack

      puts "Installing the latest stable version of Yarn..."
      raise "Installation failed" unless run_command_in_project_dir("yarn set version stable")

      puts "Adding \"packageManager\" entry to \"package.json\"..."
      enable_yarn_in_project(use_plug_and_play)

      puts "Downloading front-end packages for your application..."
      run_command_in_project_dir("yarn install")

      add_plug_and_play_for_vs_code if use_plug_and_play
    end

    private

    WARN_CACHE =
      <<~TEXT
        You may be interested in using git submodule for .yarn/cache directory. See more:
        https://github.com/yarnpkg/berry/discussions/4845#discussioncomment-3637094
      TEXT

    private_constant :WARN_CACHE

    def enable_yarn_in_project(use_plug_and_play)
      add_yarn_to_project

      if use_plug_and_play
        enable_plug_and_play
      else
        update_yarnrc_yml(add: {"nodeLinker" => "node-modules"})
      end
    end

    def enable_plug_and_play
      yarnrc_yml_changes = {}

      # @see https://yarnpkg.com/migration/pnp#enabling-yarn-pnp
      yarnrc_yml_changes["nodeLinker"] = "pnp"

      # @see https://yarnpkg.com/advanced/lexicon#local-cache
      # @see https://yarnpkg.com/features/caching#zero-installs
      # Not recommended for projects with many dependencies.
      if use_zero_installs?
        yarnrc_yml_changes["enableGlobalCache"] = "false"
        StringUtils.warning(WARN_CACHE.split("\n"))
      end

      puts "Updating .yarnrc.yml file..."
      yarnrc_yml = update_yarnrc_yml(add: yarnrc_yml_changes)

      # @see https://yarnpkg.com/getting-started/qa#which-files-should-be-gitignored
      puts "Updating .gitignore file..."
      update_gitignore_for_yarn(yarnrc_yml)
    end

    def add_plug_and_play_for_vs_code
      # Should be called after installing packages. If we call it before `yarn install`, we get:
      #     Internal Error: This tool can only be used with projects using Yarn Plug'n'Play
      # @see https://yarnpkg.com/getting-started/editor-sdks#tools-currently-supported
      puts "Adding Yarn Plug'n'Play support to VS Code..."
      run_command_in_project_dir("yarn dlx @yarnpkg/sdks vscode")
    end

    def enable_corepack
      # @see https://yarnpkg.com/getting-started/install
      # @see https://nodejs.org/api/corepack.html
      res = `corepack enable`
      return if $CHILD_STATUS.exitstatus == 0 # $CHILD_STATUS is $?

      if res.include?("permission denied")
        puts "Corepack (part of NPM) requires sudo privileges for creating symlinks."
        return if system("sudo corepack enable")
      end

      raise "Cannot enable Corepack that is required for Yarn."
    end

    def add_yarn_to_project
      # WARN: `yarn --version` may return "3.2.0", but directory `${project}/.yarn/releases`
      # contains newer release, for example, 3.6.3.
      yarn_binary = Dir["#{cli.app_path}/.yarn/releases/*.cjs"].max
      version = yarn_binary ? yarn_binary.match(/(\d\.\d\.\d)\.cjs$/)[1] : `yarn --version`.strip

      if project_file_exist?("package.json")
        run_command_in_project_dir("npm pkg set packageManager=yarn@#{version}")
      else
        json = <<~JSON
          {"packageManager": "yarn@#{version}"}
        JSON
        write_project_file("package.json", json)
      end
    end

    def use_plug_and_play?
      cli.ask.question(
        type: :boolean,
        label: "Use Plug'n'Play in Yarn - it should not be used with React Native",
        default: ->(_, _) { "y" }
      )
    end

    def use_zero_installs?
      cli.ask.question(
        type: :boolean,
        label: "Use Zero-installs - store packages (.yarn/cache) in project repo",
        default: ->(_, _) { "n" }
      )
    end

    def update_yarnrc_yml(add: {})
      lines = project_file_exist?(".yarnrc.yml") ? read_project_file(".yarnrc.yml").split("\n") : []

      replace_options_in_yarnrc_yml(lines, add)

      # Append missing options.
      add.each do |key, value|
        lines << "#{key}: #{value}"
      end

      # Keep blank line at the end of file.
      lines.reject!(&:empty?)
      lines << ""

      write_project_file(".yarnrc.yml", lines.join("\n"))
      convert_yarnrc_yml_to_hash(lines)
    end

    def replace_options_in_yarnrc_yml(lines, add)
      lines.each_with_index do |line, index|
        # Replace options in-line.
        add.each do |key, value|
          if line.start_with?("#{key}:")
            lines[index] = "#{key}: #{value}"
            add.delete(key)
          end
        end
      end
    end

    def convert_yarnrc_yml_to_hash(lines)
      result =
        lines.filter_map do |line|
          line = line.strip
          line.split(":", 2).map(&:strip) if !line.empty? && !line.start_with?("#")
        end

      result.to_h
    end

    def update_gitignore_for_yarn(yarnrc_yml)
      entries = [
        ".yarn/*",
        "!.yarn/patches",
        "!.yarn/sdks",
        "!.yarn/versions",
      ]

      entries << (yarnrc_yml["enableGlobalCache"] == "false" ? "!.yarn/cache" : ".pnp.*")

      update_ignore_file(".gitignore", add: entries)
    end
  end
end
