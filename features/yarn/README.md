# yarn

This script installs latest version of Yarn and adds actual config values for Yarn in
project directory.

1. This script asks you about [Plug'n'Play](https://yarnpkg.com/migration/pnp#enabling-yarn-pnp) &
   [Zero-installs](https://yarnpkg.com/features/caching#zero-installs) features in Yarn.
2. Also it adds entries to `.gitignore` file.
3. And adds Yarn Plug'n'Play support to VS Code.

For other developers or PCs it is enough to run `corepack enable` command once and everything will
work just fine. Corepack downloads Yarn version specified in project directory.
And, as usual, they should run `yarn install` command to download packages for front-end.
