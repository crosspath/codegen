require_relative 'functions.rb'

gem 'data_migrate'

after_bundle_install do
  if `bundle show | grep capistrano`.present?
    append_to_file('Capfile', "require 'capistrano/data_migrate'\n")
  end
end

environment(nil, env: 'development') do
  "config.middleware.use CheckDataMigration"
end

f(
  'app/middlewares/check_data_migration.rb',
  'data-migrations/check_data_migration.rb'
)
