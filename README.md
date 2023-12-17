# Project templates for Rails

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

## Features

* `bundle-config`: predefined config files for `bundler`
* `docker`: generate Dockerfile & Docker Compose files
* `misc`: miscellaneous tasks for changing and removing files and directories within
  Rails application
* `remove-comments`: remove unnecessary comments from project files
* `sort-config`: sort configuration lines in `config/environments/*.rb`
* `yarn`: install latest version of Yarn and add actual config values for Yarn

... to be continued ...

## Testing

Run `rake` or `rake test`.
