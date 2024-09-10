# Project templates for Rails

Minimal supported versions:

- Ruby 3.1 (with YJIT)
- Rails 7.2
- Node.js 20
- Yarn 4
- MySQL 8
- PostgreSQL 16
- Docker 26
- Vue 3
- Svelte 4
- Docker 26

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

Supported Rails versions: 7.2.

## Features

* `bundle-config`: predefined config files for `bundler`
* `crud`: default implementation of CRUD actions
* `docker`: generate Dockerfile & Docker Compose files
* `dotenv`: add gem `dotenv` and example files for configuration via ENV
* `misc`: miscellaneous tasks for changing and removing files and directories within
  Rails application
* `remove-comments`: remove unnecessary comments from project files
* `settings`: store project configuration in YAML or JSON format
* `sort-config`: sort configuration lines in `config/environments/*.rb`
* `testing`: add gems and default configuration for testing
* `tools`: add linters, code formatters and documentation tools
* `yarn`: install latest version of Yarn and add actual config values for Yarn

... to be continued ...

## Suggested workflow

1. Create new project directory with `new.rb` (with `bundle_install: false`).
2. Go to project directory and apply changes from `bundle-config` (replace "project-directory" to
   actual path):
```shell
change.rb project-directory bundle-config
```
3. Add some gems, if needed. Run `bundle install` and `bin/postinstall`, if needed.
4. Apply changes from other features.
5. Run `bundle install`.
6. Run `cd .tools && bundle install && cd ..` if you added `tools` feature.
7. Run `bin/postinstall`, if needed.
8. Run `bin/rubocop` to fix manually issues from RuboCop (if you added it to your project).
   Script bin/postinstall` applies "safe" corrections so you don't need to do it manually.

## Testing

Run `rake` or `rake test` to run all tests.

Run `rake test TEST=test/template_test.rb TESTOPTS="--name=test_full_7"` or similar keystroke to run
one specific test.

## Note: general requirements for Rails projects

Required system packages:
* libyaml-dev / libyaml-devel
