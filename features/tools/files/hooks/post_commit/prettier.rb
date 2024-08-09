# frozen_string_literal: true

# Run after updating this file:
#   bin/overcommit --sign post-commit
module Overcommit::Hook::PostCommit
  # Prettier formats your files with code.
  class Prettier < Base
    # Main action of this hook.
    def run
      result = execute(command, args: ["--write", *applicable_files])
      return :fail, result.stdout unless result.success?

      :pass
    end
  end
end
