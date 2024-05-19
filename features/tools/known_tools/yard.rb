# frozen_string_literal: true

module Features::Tools::KnownTools
  class Yard < Features::Tools::KnownTool
    register_as "YARD (code documentation tool)"

    def call(_use_tools)
      puts "Add YARD..."

      copy_files_to_project("bin/yard", DIR_BIN)

      warning("Run this line after `bundle install`:\nbin/yard config --gem-install-yri")
    end

    def use?
      Features::Tools::ToolRegistry.all["solargraph"].selected || super
    end
  end
end
