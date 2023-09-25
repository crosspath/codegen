# frozen_string_literal: true

module Features
  class Yarn < Feature
    register_as "yarn"

    def call
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

    private

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
  end
end
