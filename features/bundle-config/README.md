# bundle-config

Predefined config files for `bundler`:

1. Do not show messages after installing gems.
2. Do not install `production` gems in development env.
3. Do not install `development` & `test` gems in production env.
4. Use path "vendor/bundle" for gems in production env.

These config files should be in project repository.
This script adds correct entries to `.gitignore` & `.dockerignore` files.

For other developers or PCs it is enough to run `bin/setup` script in project directory once
to get file `.bundle/config` copied from `.bundle/config.development`.
