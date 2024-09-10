# misc

This script performs miscellaneous tasks:

* merges `db:prepare`, `log:clear` and `tmp:clear` tasks in `bin/setup` script
* removes `restart` task from `bin/setup` script
* removes `config/locales/en.yml` if this file contains only comments and an example entry
* removes `app/helpers` directory if it includes only example files
* removes these directories if they include only `**/.keep` files:
  * lib/assets
  * test/helpers
  * vendor
* adds common local file name patterns to `.gitignore` & `.dockerignore`

No special actions required from other developers or PCs.
