# bundle-config

Predefined config files for `bundler`:

1. Do not show messages after installing gems.
2. Ignore some environments during `bundle install` (see table below).
3. Use path "vendor/bundle" for gems in production env.

App env     | Ignored envs
------------|------------------------------
ci          | development, production, test
development | ci, production
production  | ci, development, test
test        | ci, production

These config files should be in project repository.
This script adds correct entries to `.gitignore` & `.dockerignore` files.

For other developers or PCs it is enough to run `bin/setup` script in project directory once
to get file `.bundle/config` copied from `.bundle/config.development`.
