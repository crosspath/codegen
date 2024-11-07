#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI example:
# ./new.rb
# ./new.rb file-name-with-options
# NO_SAVE=1 ./new.rb file-name-with-options

require_relative "src/ask"
require_relative "src/new_project/cli"

begin
  cli = NewProject::CLI.new(ARGV)

  puts "Press Ctrl+C to stop anytime."
  cli.call

  cli.ensure_gem_path_is_writable do
    puts "Installing railties gem..."
    cli.install_railties

    puts "Generating application..."
    cli.generate_app
    cli.add_postinstall_steps
  end

  if cli.any_postinstall_steps?
    puts "Run postinstall script..."
    cli.run_postinstall_script
  end

  puts "Done!"
rescue Interrupt
  exit(2)
rescue StandardError => e
  warn "Current dir: #{Dir.pwd}", e.message, e.backtrace.grep_v(/ruby|bundle|gems/)
  exit(1)
end
