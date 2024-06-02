# frozen_string_literal: true

# Config for Markdown lint tool, v0.13.0
#
# @see https://github.com/markdownlint/markdownlint/blob/main/docs/configuration.md
# @see https://github.com/markdownlint/markdownlint/blob/main/docs/RULES.md
#
# DSL in scope of MarkdownLint::Style.
# Replace `rule` to `exclude_rule` and comment its parameters to disable the rule.

rule "MD001"
rule "MD002"
rule "MD003", style: :atx
rule "MD004", style: :sublist
rule "MD005"
rule "MD006"
rule "MD007", indent: 4
rule "MD009", br_spaces: 2
rule "MD010"
rule "MD011"
rule "MD012"
rule "MD013", line_length: 100
rule "MD014"
rule "MD018"
rule "MD019"
rule "MD020"
rule "MD021"
rule "MD022"
rule "MD023"
rule "MD024", allow_different_nesting: true
rule "MD025"
rule "MD026", punctuation: ".,;:"
rule "MD027"
rule "MD028"
rule "MD029", style: :ordered
rule "MD030"
rule "MD031"
rule "MD032"
rule "MD033", allowed_elements: "table, tr, th, td"
rule "MD034"
rule "MD035", style: "---"
rule "MD036"
rule "MD037"
rule "MD038"
rule "MD039"
rule "MD040"
rule "MD041"
rule "MD046"
rule "MD047"
rule "MD055"
rule "MD056"
rule "MD057"
