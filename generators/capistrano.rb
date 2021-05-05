def capistrano_sidekiq(answers)
  product_name = answers[:product_name] || "Product #{Time.now.to_i.to_s(36)}"
  with_dashes  = product_name.gsub(' ', '-')
  service_name = "sidekiq-#{with_dashes}"
  path         = "/home/deploy/#{with_dashes}"

  erb(
    'bin/add-sidekiq-systemd',
    'capistrano/add-sidekiq-systemd.erb',
    product_name: product_name,
    service_name: service_name,
    path:         path
  )

  after_bundle_install do
    requires = <<~END
      require 'capistrano/sidekiq'

      install_plugin Capistrano::Sidekiq
      install_plugin Capistrano::Sidekiq::Systemd
    END
    $main.append_to_file('Capfile', requires)

    deploy_conf = <<~END
      set :init_system, :systemd
      set :service_unit_name, '#{service_name}'
    END

    $main.inject_into_file(
      'config/deploy.rb',
      deploy_conf,
      before: 'set :application'
    )
  end
end

def capistrano_after_bundle
  $main.run 'bundle binstubs capistrano'
  $main.remove_file 'bin/capify'
  $main.run 'bin/cap install'

  requires = <<~END

    require 'capistrano/data_migrate'
    require 'capistrano/yarn'
  END
  $main.append_to_file('Capfile', requires)

  uncomment = [
    'require "capistrano/rvm"',
    'require "capistrano/bundler"',
    'require "capistrano/rails/assets"',
    'require "capistrano/rails/migrations"',
    'require "capistrano/passenger"',
  ]

  uncomment.each do |x|
    replace_strings('Capfile', {from: "\# #{x}", to: x})
  end

  deploy_conf = <<~END
    set :rvm_ruby_version, '#{RUBY_VERSION}'

    set :passenger_restart_with_touch, true
  END

  $main.inject_into_file(
    'config/deploy.rb',
    deploy_conf,
    before: 'set :application'
  )

  path = '/var/www/html' # TODO: Уточнить путь
  $main.inject_into_file(
    'config/deploy.rb',
    "set :deploy_to, '#{path}'\n",
    before: "\n# Default value for :format"
  )

  linked_files = <<~END
    append :linked_files, 'config/database.yml'
    append :linked_files, 'config/master.key'
    append :linked_files, 'config/credentials.yml.enc'
    append :linked_files, '.env.production.local'
  END

  $main.inject_into_file(
    'config/deploy.rb',
    linked_files,
    before: '# append :linked_files'
  )

  linked_dirs = <<~END
    append :linked_dirs, 'log', 'storage', 'tmp/pids', 'tmp/cache'
    append :linked_dirs, 'tmp/sockets', 'public/system', 'node_modules'
    append :linked_dirs, 'public/packs'
  END

  $main.inject_into_file(
    'config/deploy.rb',
    linked_dirs,
    before: '# append :linked_dirs'
  )
end

Generator.add_actions do |answers|
  next unless answers[:capistrano]

  $main.gem_group :development do
    $main.gem 'capistrano'
    $main.gem 'capistrano-bundler'
    $main.gem 'capistrano-passenger'
    $main.gem 'capistrano-rails'
    $main.gem 'capistrano-rails-console'
    $main.gem 'capistrano-rvm'
    $main.gem 'capistrano-sidekiq', '2.0.0.beta5' if answers[:sidekiq]
    $main.gem 'capistrano-yarn'
  end

  # $main.group :development, :production do
  #   # Для Sidekiq 6.
  #   $main.gem 'listen', '>= 3.0.5', '< 3.2'
  # end

  after_bundle_install do
    capistrano_after_bundle
  end

  capistrano_sidekiq(answers) if answers[:sidekiq]
end
