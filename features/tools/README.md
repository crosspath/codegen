# tools

This script adds support for different linters, formatters and documentation tools that may be
useful for Rails applications:

1. It creates directory `.tools` with config files for tools only.
   Your application should work fine without these tools, that's why you should not include them in
   Gemfile of your application.
2. On your choice:
    - Brakeman
    - Bundler Audit
    - Bundler Leak
    - ERB Lint
    - ESLint
    - Fasterer
    - MDL (for Markdown files)
    - Overcommit (git hooks)
    - Prettier
    - Rails Best Practices
    - Rubocop and its extensions
    - SassDoc
    - Slim Lint
    - Solargraph (linter for types in Ruby) +
      gem `rails-annotate-solargraph` (in Gemfile for application)
    - YARD
3. This script adds custom configs for selected tools.
4. This script creates shortcuts for linters in `bin` directory.

For other developers or PCs:

1. If you use Overcommit, then you should run in console: `bin/overcommit --install`
2. This script may suggest you to run some lines in terminal, for example:

   ```
   bin/yard config --gem-install-yri
   bin/overcommit --sign post-checkout
   bin/overcommit --sign pre-commit
   ```

3. You may change any config file if you want!

## Solargraph

Best practices:

1. List all source code paths in `include` and keep `exclude` as short as possible.
   See file `config/.solargraph.yml` in this directory.
2. If you use file `.solargraph.yml` in project root, you should add `exclude` into it.
   This section is not inherited from default configuration.
   See `Solargraph::Workspace::Config#config_data`.
3. Any other configuration section in the file overrides default configuration.
   Their values do not merge (concatenate).
4. Run `bin/yard gems` after `bundle install`. This command regenerates documentation from gems.
5. Use `bin/solargraph` for integration with IDE.
   This script initalizes ENV variable with path to configuration file.
   In VS Code this option is known as "Solargraph: Command Path".
   This script updates this value, so you should not do it manually.

For `rails-annotate-solargraph`:

1. This gem can work if added to Gemfile of the application.
   It isn't a linter. It does not depend on gem `solargraph`.
2. This gem saves annotations for Solargraph in file `.annotate_solargraph_schema`.
   This script adds it to '.gitignore`.
   Also it appends this file name to section `include` in configuration file for Solargraph.
