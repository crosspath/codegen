def base_bin
  d('bin', 'base-files/bin')
  $main.run('chmod +x bin/configs bin/setup bin/systemd-service')
end


def base_controller(answers)
  $main.inject_into_file(
    'app/controllers/application_controller.rb',
    before: "\nend"
  ) do
    <<-END.rstrip

  protected

  def render_json_errors(errors)
    render json: { errors: errors }, status: 422
  end

  def with_form(form)
    if form.success
      yield form
    else
      render_json_errors(form.errors)
    end
  end
    END
  end
end

def base_layout(answers)
  if answers[:slim]
    base_layout_slim(answers)
  else
    base_layout_erb(answers)
  end
end

def base_layout_erb(answers)
  $main.inject_into_file(
    'app/views/layouts/application.html.erb',
    before: '    <%= csrf_meta_tags %>'
  ) do
    <<-END
    <meta charset="utf-8">
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
    skip_turbolinks: !answers[:turbolinks]
  )

  $main.remove_file('app/views/layouts/application.html.erb')
end

def base_scss(answers)
  css_files = [
    'app/assets/stylesheets/application.css',
    'app/assets/stylesheets/application.sass.scss',
  ]

  $main.create_file("#{css_dir(answers)}/application.scss") do
    existing = css_files.each_with_object('') do |file_path, buffer|
      buffer << File.read(file_path) << "\n" if File.exist?(file_path)
    end

    existing.gsub!(%r{/\*(.*)\*/}m, '')
    existing.gsub!(%r{ *//.*?$}m, '')
    existing.strip!

    existing
  end

  css_files.each { |x| $main.remove_file(x) }
end

def base_locale_ru
  $main.initializer 'i18n.rb', <<~END
    Rails.application.configure do
      config.i18n.available_locales = ['ru']
      config.i18n.default_locale = 'ru'
      config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.yml')]
    end
  END
end

def base_gems(answers)
  use_sass = !answers[:webpack]

  puts '      reset required gem versions'
  gems = %w[pg puma]
  gems.each do |name|
    $main.gsub_file('Gemfile', /^#[^\n]*\ngem ['"]#{name}['"].*$/, "gem '#{name}'")
  end

  gems = %w[web-console]
  puts "      remove    #{gems.join(', ')}"
  gems.each do |name|
    $main.gsub_file('Gemfile', /\n\s*#[^\n]*\n\s*gem ['"]#{name}['"].*$/, '')
  end

  $main.gem 'slim-rails' if answers[:slim]
  $main.gem 'rails-i18n'

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

  $main.environment(nil, env: 'development') do
    "config.middleware.use CheckDataMigration"
  end

  $main.prepend_to_file('config/environments/development.rb') do
    "require Rails.root.join('app/middlewares/check_data_migration')\n"
  end

  f('app/middlewares/check_data_migration.rb', 'data-migrations/check_data_migration.rb')
end

def base_spring(answers)
  $main.gem_group :development, :test do
    $main.gem 'spring' if answers[:spring]
  end

  $main.environment(nil, env: 'test') do
    'config.cache_classes = false'
  end

  after_bundle_install do
    $main.run 'bundle exec spring binstub --all'
  end
end

def base_vendor
  if empty_dir?('vendor')
    $main.remove_dir('vendor')
    text = <<~END
      # Mark any vendored files as having been vendored.
      vendor/* linguist-vendored
    END
    $main.gsub_file('.gitattributes', text, '')
  end
end
