# frozen_string_literal: true

module Features
  module Misc
    class ConfigFiles < Feature
      def call
        ADDITIONS.each_key { |key| change_config_for(key) }
      end

      private

      ADDITIONS = {
        development: [
          "config.active_record.strict_loading_by_default = false",
        ].freeze,
        production: [
          "config.active_record.strict_loading_by_default = true",
          "config.require_master_key = false",
          "config.ssl_options = {hsts: false}",
        ].freeze,
        test: [
          "config.active_record.strict_loading_by_default = true",
        ].freeze,
      }.freeze

      private_constant :ADDITIONS

      def change_config_for(env)
        file_name = "config/environments/#{env}.rb"
        file = read_project_file(file_name)
        append_lines = StringUtils.indent(ADDITIONS[:env]).join("\n\n")

        file.sub!("\nend", "\n#{append_lines}\nend")
        wrie_project_file(file_name, file)
      end
    end
  end
end
