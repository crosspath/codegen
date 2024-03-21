# frozen_string_literal: true

module Features
  class Linters < Feature
    register_as "linters"

    def call
      linters = select_linters
      extensions = linters[:rubocop] ? select_extensions : {}

      overcommit = use?("Overcommit (it calls linters via git hooks)")
      yard = linters[:solargraph] || use?("YARD (code documentation tool)")

      include_linters = linters.values.any?(true)
      standalone_dir = overcommit || include_linters

      if !standalone_dir && !yard
        puts "Nothing to do!"
        return
      end

      run_command_in_project_dir("mkdir -m 0755 -p .linters/config") if include_linters
      run_command_in_project_dir("mkdir -m 0755 -p .linters/git-hooks") if overcommit

      inject_brakeman if linters[:brakeman]
      inject_bundler_audit if linters[:bundler_audit]
      inject_bundler_leak if linters[:bundler_leak]
      inject_fasterer if linters[:fasterer]
      inject_mdl if linters[:mdl]
      inject_rails_best_practices if linters[:rails_best_practices]
      inject_rubocop(extensions:) if linters[:rubocop]
      inject_slim_lint if linters[:slim_lint]
      inject_solargraph if linters[:solargraph]

      inject_yard(standalone_dir:) if yard
      inject_overcommit(linters:) if overcommit

      if standalone_dir
        puts "Create Gemfile for directory `.linters`..."

        erb("Gemfile", ".linters/Gemfile", overcommit:, **linters, **extensions)
      end
    end

    private

    RUBOCOP_EXTENSIONS = %w[capybara factory_bot graphql rspec sequel].freeze

    def select_linters
      linters = {}
      linters[:brakeman] = use?("Brakeman")
      linters[:bundler_audit] = use?("Bundler Audit")
      linters[:bundler_leak] = use?("Bundler Leak")
      linters[:fasterer] = use?("Fasterer")
      linters[:mdl] = use?("MDL (for Markdown files)")
      linters[:rails_best_practices] = use?("Rails Best Practices")
      linters[:rubocop] = use?("Rubocop")
      linters[:slim_lint] = use?("Slim Lint")
      linters[:solargraph] = use?("Solargraph (check YARD annotations)")
      linters
    end

    def select_extensions
      gems = application_gems
      RUBOCOP_EXTENSIONS.each_with_object({}) { |e, a| a[e] = gems.include?(e) }
    end

    def use?(name)
      cli.ask.yes?(label: "Use #{name}", default: ->(_, _) { "y" })
    end

    def application_gems
      gemfile_lock = read_project_file("Gemfile.lock").split("\n")
      lines = gemfile_lock
      result = []

      loop do
        # +1 means "skip lines 'GEM', 'remote', 'specs'"
        gem_list_index = lines.find_index { |line| line == "GEM" }&.+(3)
        break unless gem_list_index

        lines = lines[gem_list_index..]
        result += lines.take_while { |line| !line.empty? }
      end

      raise "Cannot find 'GEM' section in Gemfile.lock" if result.empty?

      result.map! { |line| line[/\S+/] }
      result.uniq!
      result.sort!
      result
    end

    def inject_brakeman
      puts "Add Brakeman..."

      copy_files_to_project("config/brakeman.yml", ".linters/config")
      copy_files_to_project("bin/brakeman", "bin")
    end

    def inject_bundler_audit
      puts "Add Bundler Audit..."

      copy_files_to_project("bin/bundle-audit", "bin")
    end

    def inject_bundler_leak
      puts "Add Bundler Leak..."

      copy_files_to_project("bin/bundle-leak", "bin")
    end

    def inject_fasterer
      puts "Add Fasterer..."

      copy_files_to_project("config/.fasterer.yml", ".linters/config")
      copy_files_to_project("bin/fasterer", "bin")
    end

    def inject_mdl
      puts "Add MDL..."

      copy_files_to_project("config/mdl_style.rb", ".linters/config")
      copy_files_to_project("bin/mdl", "bin")
    end

    def inject_rails_best_practices
      puts "Add Rails Best Practices..."

      copy_files_to_project("config/rails_best_practices.yml", ".linters/config")
      copy_files_to_project("bin/rails_best_practices", "bin")
    end

    def inject_rubocop(extensions:)
      puts "Add Rubocop..."

      erb("config/rubocop", ".linters/config/rubocop.yml", **extensions)
      copy_files_to_project("bin/rubocop", "bin")
    end

    def inject_slim_lint
      puts "Add Slim Lint..."

      copy_files_to_project("config/.slim-lint.yml", ".linters/config")
      copy_files_to_project("bin/slimlint", "bin")
    end

    def inject_solargraph
      puts "Add Solargraph..."

      copy_files_to_project("config/.solargraph.yml", ".linters/config")
      copy_files_to_project("bin/solargraph", "bin")
      copy_files_to_project("tasks", "lib/tasks")

      puts "Update settings for integration between Solargraph and VS Code..."

      if project_file_exist?(".vscode/settings.json")
        file_path = File.join(feature_dir, "files", "vscode/settings.json")
        existing_settings = read_project_file(".vscode/settings.json")
        new_settings = merge_jsons(existing_settings, File.read(file_path))
        write_project_file(".vscode/settings.json", new_settings)
      else
        copy_files_to_project("vscode", ".vscode")
      end

      add_gem_for_development("rails-annotate-solargraph")

      puts "Add documentation schema file to `.gitignore`..."

      update_ignore_file(".gitignore", add: ".annotate_solargraph_schema")

      puts "Copy documentation schema file..."

      copy_files_to_project(".annotate_solargraph_schema", "")
    end

    def merge_jsons(*files)
      result = file_paths.map { |f| JSON.parse(f) }.reduce(&:merge)
      JSON.pretty_generate(result)
    end

    def add_gem_for_development(name)
      puts "Add gem #{name}..."

      gemfile = read_project_file("Gemfile") + "\ngem \"#{name}\", group: :development\n"
      write_project_file("Gemfile", gemfile)
    end

    def inject_yard(standalone_dir:)
      puts "Add YARD..."

      erb("bin/yard", "bin", standalone_dir:)
      warning("Run this line after `bundle install`:\nbin/yard config --gem-install-yri")

      add_gem_for_development("yard") unless standalone_dir
    end

    def inject_overcommit(linters:)
      puts "Add Overcommit..."

      warnings = []

      copy_files_to_project("config/.solargraph.yml", ".linters/config")
      copy_files_to_project("bin/overcommit", "bin")

      # TODO: Generate config file.

      if linters[:bundler_audit] || linters[:bundler_leak]
        puts "Add post-checkout git hook for updating gems data..."

        erb(
          "git-hooks/post_checkout/update_gems_data",
          ".linters/git-hooks/post_checkout/update_gems_data.rb",
          **linters
        )

        warnings << "Run this line after `bundle install`:\nbin/overcommit --sign post-checkout"
      end

      if linters[:bundler_leak]
        puts "Add pre-commit git hook for Bundler Leak..."

        copy_files_to_project("git-hooks/pre_commit/bundle_leak.rb", "git-hooks/pre_commit")
      end

      puts "Add fix for pre-commit git hook for YamlSyntax checker..."

      copy_files_to_project("git-hooks/pre_commit/yaml_syntax_checker.rb", "git-hooks/pre_commit")
      warnings << "Run this line after `bundle install`:\nbin/overcommit --sign pre-commit"

      warning(warnings.join("\n\n"))
    end
  end
end
