gem_group :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

after_bundle_install do
  run 'bundle binstubs rspec-core'
end
