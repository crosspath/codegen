# frozen_string_literal: true

module NewProject
  module ConfigFile
    extend self

    def read_options_from_file(file_path)
      return {} if file_path.nil? || file_path.empty?

      File.readlines(file_path).to_h do |line|
        k, v = line.split(":", 2).map(&:strip)
        [k.to_sym, v]
      end
    end

    def generate(gopt)
      gopt.each_with_object("".dup) do |(key, value), acc|
        value = value.join(", ") if value.is_a?(Array)
        acc << "#{key}: #{value}\n"
      end
    end
  end
end
