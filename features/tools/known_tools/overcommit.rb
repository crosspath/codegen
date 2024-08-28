# frozen_string_literal: true

require_relative "../sign_scripts_for_overcommit"

module Features::Tools
  module KnownTools
    class Overcommit < KnownTool
      register_as "Overcommit (it calls other tools via git hooks)"

      def call(use_tools)
        puts "Add Overcommit..."

        options = {}
        copy_files_to_project("bin/overcommit", DIR_BIN)

        puts "Generate config file for Overcommit..."

        # This file should be stored in application root directory, not in `.tools`.
        erb(".overcommit", ".overcommit.yml", **use_tools)

        if use_tools["bundler_audit"] || use_tools["bundler_leak"]
          add_hook_for_update_gems_data(use_tools)

          options[:post_checkout] = true
        end

        add_pre_commit_hook_for_bundler_leak if use_tools["bundler_leak"]

        if use_tools["prettier"]
          add_post_commit_hook_for_prettier

          options[:post_commit] = true
        end

        add_pre_commit_hook_for_yaml

        cli.post_install_script.add_steps(SignScriptsForOvercommit.with_options(options))
      end

      private

      def add_hook_for_update_gems_data(use_tools)
        puts "Add post-checkout git hook for updating gems data..."

        dir = File.join(DIR_HOOKS, "post_checkout")

        create_project_dir(dir)

        erb(
          "hooks/post_checkout/update_gems_data",
          File.join(dir, "update_gems_data.rb"),
          **use_tools
        )
      end

      def add_pre_commit_hook_for_bundler_leak
        puts "Add pre-commit git hook for Bundler Leak..."

        dir = File.join(DIR_HOOKS, "pre_commit")

        create_project_dir(dir)
        copy_files_to_project("hooks/pre_commit/bundle_leak.rb", dir)
      end

      def add_post_commit_hook_for_prettier
        puts "Add post-commit git hook for Prettier..."

        dir = File.join(DIR_HOOKS, "post_commit")

        create_project_dir(dir)
        copy_files_to_project("hooks/post_commit/prettier.rb", dir)
      end

      def add_pre_commit_hook_for_yaml
        puts "Add fix for pre-commit git hook for YamlSyntax checker..."

        dir = File.join(DIR_HOOKS, "pre_commit")

        create_project_dir(dir)
        copy_files_to_project("hooks/pre_commit/yaml_syntax_checker.rb", dir)
      end
    end
  end
end
