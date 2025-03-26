# frozen_string_literal: true

require_relative "bin_scripts"
require_relative "config_files"
require_relative "dirs"
require_relative "ignore_files"
require_relative "locales"

module Features
  module Misc
    class MiscMain < Feature
      register_as "misc"

      def call
        [BinScripts, ConfigFiles, Dirs, IgnoreFiles, Locales].each do |klass|
          klass.new(cli).call
        end
      end
    end
  end
end
