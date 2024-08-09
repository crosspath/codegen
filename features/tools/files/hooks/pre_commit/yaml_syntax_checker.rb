# frozen_string_literal: true

# Run after updating this file:
#   bin/overcommit --sign pre-commit
require "overcommit/hook/pre_commit/yaml_syntax"

module Overcommit::Hook::PreCommit
  # Same class for checking syntax in YAML files, as bundled in Overcommit.
  class YamlSyntaxChecker < YamlSyntax
    private

    # Class in Overcommit tries to read renamed & removed files. We should skip them.
    def applicable_files
      super.select { |file| File.exist?(file) }
    end
  end
end
