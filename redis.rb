$main ||= self

require_relative 'functions.rb'

gem 'redis'

environment(nil, env: 'production') do
  "config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }"
end

%w[.env.development .env.production .env.test].each do |file_name|
  af(file_name, "REDIS_URL=redis://localhost:6379/0\n")
end

d('app/models', 'redis')
