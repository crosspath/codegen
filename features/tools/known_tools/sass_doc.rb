# frozen_string_literal: true

module Features::Tools::KnownTools
  class SassDoc < Features::Tools::KnownTool
    register_as "SassDoc", adds_config: true

    def call(_use_tools)
      puts "Add SassDoc..."
    end
  end
end
