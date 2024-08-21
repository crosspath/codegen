# frozen_string_literal: true

module Features
  class RemoveComments < Feature
    register_as "remove-comments"

    def call
      remove_comments_from_gemfile

      %w[.dockerignore .gitattributes .gitignore].each do |file|
        update_ignore_file(file) if project_file_exist?(file)
      end

      remove_comments_from_ruby_file("config/application.rb")
      remove_comments_from_ruby_file("config/environment.rb")
      remove_comments_from_ruby_file("db/seeds.rb")

      remove_comments_from_config_env
    end

    private

    COMMENT = /^\s*#/
    COMMENTED_REQUIRE = /^\s*#\s(require|require_relative)\s/

    GEM_REQUIREMENT = /^\s*#?\s*gem/
    GEM_REQUIREMENT_OR_END = /#{GEM_REQUIREMENT}|^\s*end/

    private_constant :COMMENT, :COMMENTED_REQUIRE, :GEM_REQUIREMENT, :GEM_REQUIREMENT_OR_END

    def remove_comments_from_ruby_file(project_file_name, &)
      return unless project_file_exist?(project_file_name)

      old_lines = read_project_file(project_file_name).lines
      new_lines = remove_comment_lines(old_lines, &)

      write_project_file(project_file_name, new_lines.join) unless new_lines.size == old_lines.size
    end

    def remove_comment_lines(old_lines, &)
      new_lines = []

      old_lines.each do |line|
        if line.strip.empty?
          new_lines << line if !new_lines.empty? && !new_lines.last.strip.empty?
        else
          new_lines << line if should_keep_line?(line, &)
        end
      end

      new_lines
    end

    def should_keep_line?(line)
      if block_given?
        yield(line)
      else
        # Оставить строку, если это не комментарий или если это закомментированный require.
        !line.match?(COMMENT) || line.match?(COMMENTED_REQUIRE)
      end
    end

    def remove_blank_lines_from_ruby_file(project_file_name)
      return unless project_file_exist?(project_file_name)

      old_lines = read_project_file(project_file_name).lines
      new_lines = remove_blank_lines(old_lines)

      write_project_file(project_file_name, new_lines.join) unless new_lines.size == old_lines.size
    end

    def remove_blank_lines(old_lines)
      old_lines.select.with_index do |line, index|
        if line.strip.empty?
          prev_line = old_lines[index - 1] || ""
          next_line = old_lines[index + 1] || ""
          yield(prev_line, next_line)
        else
          true
        end
      end
    end

    def remove_comments_from_gemfile
      remove_comments_from_ruby_file("Gemfile") do |line|
        # Remove comments but leave commented lines with gem requirement.
        match = line.match(/^\s*#\s*(.*)/)
        !match || match[1].start_with?("gem", "group")
      end

      # Remove blank lines between gem requirements.
      remove_blank_lines_from_ruby_file("Gemfile") do |prev_line, next_line|
        prev_line !~ GEM_REQUIREMENT || next_line !~ GEM_REQUIREMENT_OR_END
      end
    end

    def remove_comments_from_config_env
      Dir["config/environments/*.rb", base: cli.app_path].each do |cfg_env|
        remove_comments_from_ruby_file(cfg_env) do |line|
          # Remove comments but leave commented lines with config values and
          # some code (brackets, slashes, etc).
          match = line.match(/^\s*#\s*(.*)/)
          !match || match[1] =~ /^config\.|^\W/
        end

        # Remove blank line after "do".
        remove_blank_lines_from_ruby_file(cfg_env) do |prev_line, _next_line|
          !prev_line.strip.end_with?("do")
        end
      end
    end
  end
end
