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

d('', 'base-files')
d('contrib', 'contrib')

$main.run('chmod +x contrib/pre-commit')
$main.run('ln -s $(pwd)/contrib/pre-commit $(pwd)/.git/hooks/pre-commit')

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

erb(
  'app/views/layouts/application.html.slim',
  'base-files/layouts/application.html.slim.erb',
  skip_turbolinks: $main.options[:skip_turbolinks]
)

# rename
$main.copy_file(
  'app/assets/stylesheets/application.css',
  'app/assets/stylesheets/application.scss'
)
remove_file('app/assets/stylesheets/application.css')
