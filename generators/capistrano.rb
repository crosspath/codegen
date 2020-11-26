Generator.add_actions do |answers|
  next unless answers[:capistrano]

  $main.gem_group :development do
    $main.gem 'capistrano'
    $main.gem 'capistrano-bundler'
    $main.gem 'capistrano-passenger'
    $main.gem 'capistrano-rails'
    $main.gem 'capistrano-rails-console'
    $main.gem 'capistrano-rvm'
    $main.gem 'capistrano-sidekiq', '2.0.0.beta5'
    $main.gem 'capistrano-yarn'
  end

  # $main.group :development, :production do
  #   # Для Sidekiq 6.
  #   $main.gem 'listen', '>= 3.0.5', '< 3.2'
  # end

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
    $main.run 'bundle binstubs capistrano'
    $main.run 'bin/cap install'

    requires = <<~END

      require 'capistrano/data_migrate'
      require 'capistrano/yarn'
      require 'capistrano/sidekiq'

      install_plugin Capistrano::Sidekiq
      install_plugin Capistrano::Sidekiq::Systemd
    END
    $main.append_to_file('Capfile', requires)

    uncomment = [
      'require "capistrano/rvm"',
      'require "capistrano/bundler"',
      'require "capistrano/rails/assets"',
      'require "capistrano/rails/migrations"',
      'require "capistrano/passenger"',
    ]

    replace_strings('Capfile', uncomment.map { |x| {from: "\# #{x}", to: x} })

    deploy_text = <<~END
    # Разворачивание на сервере

        bin/cap production deploy
    END

    $main.append_to_file('README.md', deploy_text)

    deploy_conf = <<~END
      set :rvm_ruby_version, '2.6.5'

      set :passenger_restart_with_touch, true

      set :sidekiq_service_unit_name, '#{service_name}'
    END

    $main.inject_into_file(
      'config/deploy.rb',
      deploy_conf,
      before: 'set :application'
    )

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
end
