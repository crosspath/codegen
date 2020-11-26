Generator.add_actions do |answers|
  next unless answers[:capistrano]

  $main.gem_group :development do
    $main.gem 'capistrano'
    $main.gem 'capistrano-bundler'
    $main.gem 'capistrano-rails'
    $main.gem 'capistrano-rails-console'
    $main.gem 'capistrano-rvm'
  end

  after_bundle_install do
    $main.run 'bundle binstubs capistrano'
    $main.run 'bin/cap install'
    $main.append_to_file('Capfile', "require 'capistrano/data_migrate'\n")
  end
end
