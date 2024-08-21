# frozen_string_literal: true

module Features
  module Misc
    class Locales < Feature
      def call
        return unless project_file_exist?(LOCALES_EN)

        puts "Check #{LOCALES_EN} file..."

        require "psych"

        file_contents = Psych.safe_load(read_project_file(LOCALES_EN))
        remove_project_file(LOCALES_EN) if file_contents == LOCALES_EN_CONTENTS
      end

      LOCALES_EN = "config/locales/en.yml"
      LOCALES_EN_CONTENTS = {"en" => {"hello" => "Hello world"}}.freeze

      private_constant :LOCALES_EN, :LOCALES_EN_CONTENTS
    end
  end
end
