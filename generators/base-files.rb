def base_gitignore
  $main.append_to_file(
    '.gitignore',
    <<-LINE

*.local
.DS_Store
.directory
Thumbs.db
[Dd]esktop.ini
~$*

/vendor/*
!/vendor/.keep
    LINE
  )
end

def base_root
  d('', 'base-files')
  d('', 'config/env')
end

def base_bin
  d('bin', 'base-files/bin')
  $main.run('chmod +x bin/configs bin/setup')
end

def base_dir(dir)
  d("app/#{dir}", "base-files/#{dir}")
end

def base_controller(answers)
  $main.inject_into_file(
    'app/controllers/application_controller.rb',
    before: "\nend"
  ) do
    <<-END.rstrip

  protected

  def with_form(form)
    if form.success
      yield form
    else
      render_json_errors(form.errors)
    end
  end

  def render_json_errors(errors)
    render json: { errors: errors }, status: 422
  end
    END
  end
end

def base_layout_erb(answers)
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
    "\n    <%= AlertsPresenter.flashes(self) %>",
    after: '<body>'
  )
end

def base_layout_slim(answers)
  erb(
    'app/views/layouts/application.slim',
    'base-files/layouts/application.slim.erb',
    skip_turbolinks: $main.options[:skip_turbolinks]
  )

  $main.remove_file('app/views/layouts/application.html.erb')
end

def base_scss(answers)
  css_file = 'app/assets/stylesheets/application.css'

  $main.create_file("#{css_dir(answers)}/application.scss") do
    next unless File.exist?(css_file)
    existing = File.read(css_file)

    existing.gsub!(%r{/\*(.*)\*/}m, '')
    existing.strip!

    existing
  end

  $main.remove_file(css_file)
end

def base_locale_ru
  d('config/locales', 'config/locales')
  $main.initializer 'i18n.rb', <<~END
    require 'i18n/backend/pluralization'
    I18n::Backend::Simple.send(:include, I18n::Backend::Pluralization)

    Rails.application.config.i18n.available_locales = ['ru']
    Rails.application.config.i18n.default_locale = 'ru'
  END
end

def base_paths(answers)
  $main.initializer 'paths.rb', <<~END
    Rails.application.config.autoload_paths += %w[
      forms
      presenters
      queries
      serializers
    ]
  END
end

def base_gems(answers)
  use_sass = !answers[:webpack]

  puts '      reset required gem versions'
  gems = %w[pg puma webpacker turbolinks]
  gems << 'sass-rails' if use_sass
  gems.each do |name|
    $main.gsub_file('Gemfile', /^#[^\n]*\ngem '#{name}'.*$/, "gem '#{name}'")
  end

  gems = %w[jbuilder byebug web-console]
  gems << 'sass-rails' unless use_sass
  puts "      remove    #{gems.join(', ')}"
  gems.each do |name|
    $main.gsub_file('Gemfile', /\n\s*#[^\n]*\n\s*gem '#{name}'.*$/, '')
  end

  $main.gem 'slim-rails' if answers[:slim]

  $main.gem 'dotenv-rails'
end

def base_debug
  $main.gem_group :development do
    $main.gem 'better_errors'
    $main.gem 'binding_of_caller'
    $main.gem 'pry-rails' if RUBY_VERSION < '2.7'
  end
end

def base_data_migrations
  $main.gem 'data_migrate'

  $main.environment(nil, env: 'development') do
    "config.middleware.use CheckDataMigration"
  end

  $main.prepend_to_file('config/environments/development.rb') do
    "require Rails.root.join('app/middlewares/check_data_migration')\n"
  end

  f(
    'app/middlewares/check_data_migration.rb',
    'data-migrations/check_data_migration.rb'
  )
end

def base_lib_assets
  $main.remove_dir('lib/assets') if Dir.empty?('lib/assets')
end

def base_vendor
  if Dir.empty?('vendor')
    $main.remove_dir('vendor')
    $main.gsub_file('.gitattributes', "# Mark any vendored files as having been vendored.\n", '')
    $main.gsub_file('.gitattributes', "vendor/* linguist-vendored\n", '')
  end
end

Generator.add_actions do |answers|
  base_gitignore
  base_root
  base_bin
  base_dir('forms')
  base_dir('presenters')
  base_dir('queries')
  base_controller(answers)
  if answers[:slim]
    base_layout_slim(answers)
  else
    base_layout_erb(answers)
  end
  base_scss(answers)
  base_locale_ru
  base_paths(answers)
  base_gems(answers)
  base_debug
  base_data_migrations
  base_lib_assets
  base_vendor
end
