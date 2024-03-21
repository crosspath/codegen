# frozen_string_literal: true

# Run after updating this file:
#   bin/overcommit --sign pre-commit
module Overcommit::Hook::PreCommit
  # Make sure memory leaks are not in your gem dependencies.
  # @see https://github.com/rubymem/bundler-leak
  class BundleLeak < Base
    LOCK_FILE = "Gemfile.lock"
    COMMAND = (%w[git ls-files -o -i --exclude-standard --] + [LOCK_FILE]).freeze

    def run
      # Ignore if Gemfile.lock is not tracked by git
      ignored_files = execute(COMMAND).stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      result = execute(command)
      if result.success?
        :pass
      else
        [:warn, result.stdout]
      end
    end
  end
end
