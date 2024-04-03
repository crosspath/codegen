# frozen_string_literal: true

module Features::Tools::KnownTools
  class Overcommit < Features::Tools::KnownTool
    register_as "Overcommit (it calls other tools via git hooks)"

    def call(use_tools)
      puts "Add Overcommit..."

      warnings = []

      copy_files_to_project("bin/overcommit", DIR_BIN)

      puts "Generate config file for Overcommit..."

      # This file should be stored in application root directory, not in `.tools`.
      erb(".overcommit", ".overcommit.yml", **use_tools)

      if use_tools[:bundler_audit] || use_tools[:bundler_leak]
        add_hook_for_update_gems_data(use_tools)

        warnings << "Run this line after `bundle install`:\nbin/overcommit --sign post-checkout"
      end

      add_pre_commit_hook_for_bundler_leak if use_tools[:bundler_leak]
      add_pre_commit_hook_for_yaml

      warnings << "Run this line after `bundle install`:\nbin/overcommit --sign pre-commit"

      warning(warnings.join("\n\n"))
    end

    private

    def add_hook_for_update_gems_data(use_tools)
      puts "Add post-checkout git hook for updating gems data..."

      erb(
        "hooks/post_checkout/update_gems_data",
        File.join(DIR_HOOKS, "post_checkout/update_gems_data.rb"),
        **use_tools
      )
    end

    def add_pre_commit_hook_for_bundler_leak
      puts "Add pre-commit git hook for Bundler Leak..."

      copy_files_to_project("hooks/pre_commit/bundle_leak.rb", File.join(DIR_HOOKS, "pre_commit"))
    end

    def add_pre_commit_hook_for_yaml
      puts "Add fix for pre-commit git hook for YamlSyntax checker..."

      copy_files_to_project(
        "hooks/pre_commit/yaml_syntax_checker.rb",
        File.join(DIR_HOOKS, "pre_commit")
      )
    end
  end
end
