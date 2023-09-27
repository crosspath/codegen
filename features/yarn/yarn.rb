# frozen_string_literal: true

module Features
  class Yarn < Feature
    register_as "yarn", before: "docker"

    def call
      # @see https://yarnpkg.com/getting-started/install
      # @see https://nodejs.org/api/corepack.html
      res = `corepack enable`
      if res.include?("permission denied")
        puts "Corepack (part of NPM) requires sudo privileges for creating symlinks."
        raise "Cannot enable Corepack that is required for Yarn." unless system("sudo corepack enable")
      end

      puts "Installing the latest stable version of Yarn..."
      raise "Installation failed" unless system("cd #{cli.app_path} && yarn set version stable")

      puts "Adding \"packageManager\" entry to \"package.json\"..."
      version = `cd #{cli.app_path} && yarn --version`
      system("cd #{cli.app_path} && npm pkg set packageManager=yarn@#{version}")

      if cli.ask.yes?(label: "Use Plug'n'Play in Yarn - it should not be used with React Native", default: ->(_, _) { "y" })
        yarnrc_yml_changes = {}

        # @see https://yarnpkg.com/migration/pnp#enabling-yarn-pnp
        yarnrc_yml_changes["nodeLinker"] = "pnp"

        # @see https://yarnpkg.com/advanced/lexicon#local-cache
        # @see https://yarnpkg.com/features/caching#zero-installs
        # Not recommended for projects with many dependencies.
        if cli.ask.yes?(label: "Use Zero-installs - store packages (.yarn/cache) in project repo", default: ->(_, _) { "n" })
          yarnrc_yml_changes["enableGlobalCache"] = "false"
          puts warning(
            "You may be interested in using git submodule for .yarn/cache directory. See more:\n"\
            "https://github.com/yarnpkg/berry/discussions/4845#discussioncomment-3637094"
          )
        end

        puts "Updating .yarnrc.yml file..."
        yarnrc_yml = update_yarnrc_yml(add: yarnrc_yml_changes)

        # @see https://yarnpkg.com/getting-started/qa#which-files-should-be-gitignored
        puts "Updating .gitignore file..."
        update_gitignore_for_yarn(yarnrc_yml)

        # @see https://yarnpkg.com/getting-started/editor-sdks#tools-currently-supported
        puts "Adding Yarn Plug'n'Play support to VS Code..."
        system("cd #{cli.app_path} && yarn dlx @yarnpkg/sdks vscode")
      else
        update_yarnrc_yml(add: {"nodeLinker" => "node-modules"})
      end

      puts "Downloading front-end packages for your application..."
      system("cd #{cli.app_path} && yarn install")
    end

    private

    def update_yarnrc_yml(add: {})
      lines = project_file_exist?(".yarnrc.yml") ? read_project_file(".yarnrc.yml").split("\n") : []

      lines.each_with_index do |line, index|
        # Replace options in-line.
        add.each do |key, value|
          if line.start_with?("#{key}:")
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
      convert_yarnrc_yml_to_hash(lines)
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

      if yarnrc_yml["enableGlobalCache"] == "false"
        entries << "!.yarn/cache"
      else
        entries << ".pnp.*"
      end

      update_ignore_file(".gitignore", add: entries)
    end
  end
end
