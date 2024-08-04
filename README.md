# Project templates for Rails

Minimal supported versions:

- Ruby 3.1 (with YJIT)
- Rails 6.1
- Node.js 20
- Yarn 4
- MySQL 8
- PostgreSQL 16
- Docker 26
- Vue 3
- Svelte 4

To create project:

- run `./new.rb` and choose options in interactive mode;
- run `./new.rb file-name-with-options`, where `file-name-with-options` is the file path to your
  file with options (this script asks to create this file before running `rails new` command).

To apply changes to existing project:

- run `./change.rb` and choose options in interactive mode;
- run `./change.rb project-directory`, where `project-directory` is path to the directory of your
  project;
- run `./change.rb project-directory feature-name`, where `feature-name` is name of desired feature
  (see list of features below). You may pass several feature names separated by space.

Supported Rails versions: 6.1, 7.1.

## Features

* `bundle-config`: predefined config files for `bundler`
* `docker`: generate Dockerfile & Docker Compose files
* `dotenv`: add gem `dotenv` and example files for configuration via ENV
* `linters`: add linters for Ruby and its ecosystem
* `misc`: miscellaneous tasks for changing and removing files and directories within
  Rails application
* `remove-comments`: remove unnecessary comments from project files
* `settings`: store project configuration in YAML or JSON format
* `sort-config`: sort configuration lines in `config/environments/*.rb`
* `yarn`: install latest version of Yarn and add actual config values for Yarn

... to be continued ...

## Testing

Run `rake` or `rake test` to run all tests.

Run `rake test TEST=test/template_test.rb TESTOPTS="--name=test_full_6"` or similar keystroke to run
one specific test.
