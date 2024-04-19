#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./change.rb
# ./change.rb project-directory
# ./change.rb project-directory feature-name
# ./change.rb project-directory feature-1 feature-2 feature-3 ...

require_relative "src/change_project/cli"

Dir["#{__dir__}/features/*/*.rb"].sort.each { |f| require_relative(f) }

ChangeProject::CLI.new(ARGV.dup).call
