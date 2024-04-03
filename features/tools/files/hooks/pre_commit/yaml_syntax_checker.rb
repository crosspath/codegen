# frozen_string_literal: true

# Run after updating this file:
#   bin/overcommit --sign pre-commit
require "overcommit/hook/pre_commit/yaml_syntax"

module Overcommit::Hook::PreCommit
  # Такой же класс для проверки синтаксиса файлов YAML, как встроенный в Overcommit.
  class YamlSyntaxChecker < YamlSyntax
    private

    # Встроенный класс пытается прочитать переименованные и удалённые файлы. Пропускаем их.
    def applicable_files
      super.select { |file| File.exist?(file) }
    end
  end
end
