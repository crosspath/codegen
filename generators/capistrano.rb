Generator.add_actions do |answers|
  next unless answers[:capistrano]

  $main.gem_group :development do
    $main.gem 'capistrano'
    $main.gem 'capistrano-rvm'
    $main.gem 'capistrano-bundler'
    $main.gem 'capistrano-rails'
    $main.gem 'capistrano-rails-console'
  end

  after_bundle_install do
    $main.run 'bundle exec cap install'
  end
end
