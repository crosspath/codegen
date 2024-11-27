# frozen_string_literal: true

module NewGem
  module Options
    # Types:
    #
    # GeneratorOptionName ::= Symbol
    # RailsOptionName ::= String
    # OptionValue ::= String | true | false | Array(String)
    # GeneratorOptions ::= Hash(GeneratorOptionName, OptionValue)
    # RailsOptions ::= Hash(RailsOptionName, OptionValue)
    # OptionDefinition ::= Hash {
    #   label: String,
    #   type: :text | :boolean | :one_of | :many_of,
    #   variants: Hash(String, String), # if type == :one_of || type == :many_of
    #   default: Proc(GeneratorOptions, RailsOptions) -> OptionValue, # optional
    #   apply: Proc(GeneratorOptions, RailsOptions, OptionValue), # optional
    #   skip_if: Proc(GeneratorOptions, RailsOptions) -> true | false # optional
    # }
    # typeof OPTIONS == Hash(Symbol, OptionDefinition)
    OPTIONS = {
      gem_path: {
        label: "Gem path",
        type: :text,
      },
      name: {
        label: "Gem name",
        type: :text,
        default: ->(gopt, _ropt) do
          File.basename(gopt[:gem_path])
        rescue StandardError
          ""
        end,
      },
    }.freeze
  end
end
