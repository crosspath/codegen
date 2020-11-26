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
    with_form = <<-END.rstrip


    def with_form(form)
      if form.success
        yield form
      else
        render json: { errors: form.errors }, status: 422
      end
    end
    END

    <<-END.rstrip

    protected#{with_form}

    def render_json_errors(errors)
      render json: { errors: errors }, status: 422
    end
    END
  end
end

def base_layout(answers)
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

  if answers[:slim]
    erb(
      'app/views/layouts/application.html.slim',
      'base-files/layouts/application.html.slim.erb',
      skip_turbolinks: $main.options[:skip_turbolinks]
    )
  end
end

def base_scss
  css_file = 'app/assets/stylesheets/application.css'
  unless File.exist?(css_file)
    puts "Skip, #{css_file} does not exist"
    return
  end

  $main.create_file('app/assets/stylesheets/application.scss') do
    existing = File.read(css_file)
    requires = []

    existing.gsub!(%r{/\*(.*)\*/}m) do |match|
      match.split("\n").each do |x|
        res = x.match(/=\s*(require_.+)\Z/)
        requires << res[1] if res
      end
      ''
    end
    existing.strip!
    header = requires.map { |x| "//= #{x}\n" }

    [header, (existing.empty? ? '' : "\n"), existing].join
  end

  $main.remove_file('app/assets/stylesheets/application.css')
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
  puts '      reset required gem versions'
  %w[pg puma sass-rails webpacker turbolinks].each do |name|
    $main.gsub_file('Gemfile', /^#[^\n]*\ngem '#{name}'.*$/, "gem '#{name}'")
  end

  puts '      remove    jbuilder, byebug, web-console'
  %w[jbuilder byebug web-console].each do |name|
    $main.gsub_file('Gemfile', /\n\s*#[^\n]*\n\s*gem '#{name}'.*$/, '')
  end

  $main.gsub_file('Gemfile', "\ngroup :development, :test do\nend\n", '')

  $main.gem 'slim-rails' if answers[:slim]

  $main.gem_group :development, :test do
    $main.gem 'dotenv-rails'
  end
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

  after_bundle_install do
    if `bundle info capistrano`.include?('Summary')
      $main.append_to_file('Capfile', "require 'capistrano/data_migrate'\n")
    end
  end

  $main.environment(nil, env: 'development') do
    "config.middleware.use CheckDataMigration"
  end

  f(
    'app/middlewares/check_data_migration.rb',
    'data-migrations/check_data_migration.rb'
  )
end

Generator.add_actions do |answers|
  base_gitignore
  base_root
  base_bin
  base_dir('forms')
  base_dir('presenters')
  base_dir('queries')
  base_controller(answers)
  base_layout(answers)
  base_scss
  base_locale_ru
  base_paths(answers)
  base_gems(answers)
  base_debug
  base_data_migrations
end
