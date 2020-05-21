gem 'capistrano'
gem 'capistrano-rvm'
gem 'capistrano-bundler'
gem 'capistrano-rails'
gem 'capistrano-rails-console'

after_bundle do
  run 'bundle exec cap install'
end
