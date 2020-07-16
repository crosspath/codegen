puts '      reset required gem versions'
%w[pg puma sass-rails webpacker turbolinks].each do |name|
  $main.gsub_file('Gemfile', /^#[^\n]*\ngem '#{name}'.*$/, "gem '#{name}'")
end

puts '      remove    jbuilder, byebug, web-console'
%w[jbuilder byebug web-console].each do |name|
  $main.gsub_file('Gemfile', /\n\s*#[^\n]*\n\s*gem '#{name}'.*$/, '')
end

$main.gsub_file('Gemfile', /\ngroup :development, :test do\nend\n/, '')

$main.gem 'slim-rails'

$main.gem_group :development, :test do
  $main.gem 'dotenv-rails'
end

$main.append_to_file(
  '.gitignore',
  <<-LINE

*.local
.DS_Store
.directory
Thumbs.db
[Dd]esktop.ini
~$*

  LINE
)

if $main.yes?('Использовать ENV[DATABASE_URL] для production? (y/n)')
  production_db_url  = true
  production_db_name = ''
  puts(
    'Этот параметр можно задать на сервере; '\
    'его значение не должно попасть в репозиторий'
  )
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

d('contrib', 'contrib')

$main.run('chmod +x contrib/pre-commit')
$main.run('ln -s $(pwd)/contrib/pre-commit $(pwd)/.git/hooks/pre-commit')

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

$main.inject_into_file(
  'app/views/layouts/application.html.erb',
  before: '    <%= csrf_meta_tags %>'
) do
  <<-END
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
  END
end

$main.inject_into_file(
  'app/views/layouts/application.html.erb',
  after: '<body>'
) do
  <<-END

    <%= AlertsPresenter.flashes(self) %>
  END
end

d('app/views/layouts', 'base-files/layouts')

$main.run 'yarn add webpack-bundle-analyzer --dev'

$main.send(:after_bundle) do
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
end

# rename
copy_file(
  'app/assets/stylesheets/application.css',
  'app/assets/stylesheets/application.scss'
)
remove_file('app/assets/stylesheets/application.css')
