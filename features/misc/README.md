# misc

This script performs miscellaneous tasks:

* merges `db:prepare`, `log:clear`, and `tmp:clear` tasks in `bin/setup` script
* removes `restart` task from `bin/setup` script
* removes `config/locales/en.yml` if this file contains only comments and an example entry
* removes `app/helpers` and `test/helpers` directories if they include only example files
* removes `vendor` directory if it includes only `**/.keep` files

No special actions required from other developers or PCs.
