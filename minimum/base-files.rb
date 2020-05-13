$main.gem_group :development, :test do
  $main.gem 'dotenv-rails'
end

$main.append_to_file('.gitignore', "*.local\n.DS_Store\n.directory\n")

if $main.yes?('Использовать ENV[DATABASE_URL] для production? (y/n)')
  production_db_url  = true
  production_db_name = ''
  puts 'Этот параметр можно задать на сервере; его значение не должно попасть в репозиторий'
else
  production_db_url  = false
  production_db_name = $main.ask('Название БД для production =')
end

d('', 'base-files')

erb(
  'config/database.yml', 'base-files/config/database.yml.erb',
  use_url: production_db_url,
  db_name: production_db_name
)

d('config/locales', 'base-files/config/locales')

$main.initializer 'i18n.rb', <<-END
require 'i18n/backend/pluralization'
I18n::Backend::Simple.send(:include, I18n::Backend::Pluralization)

Rails.application.config.i18n.available_locales = ['ru']
Rails.application.config.i18n.default_locale = 'ru'
END

$main.initializer 'paths.rb', <<-END
Rails.application.config.autoload_paths += %w[
  forms
  presenters
  queries
  serializers
]
END

d('app/forms', 'base-files/forms')
d('app/presenters', 'base-files/presenters')
d('app/queries', 'base-files/queries')

$main.run 'yarn add webpack-bundle-analyzer --dev'

$main.rails_command 'webpacker:install'

$main.inject_into_file(
  'config/webpack/production.js',
  before: 'module.exports = environment.toWebpackConfig()'
) do
  <<-END
// Run `NODE_ENV=production DIAGRAM=1 bin/webpack`
// when you want to see volumes of JS packs.
if (process.env.DIAGRAM) {
  const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
  environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());
}

  END
end
