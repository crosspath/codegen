$main ||= self

require_relative 'functions.rb'

gem 'redis'

environment(nil, env: 'production') do
  "config.cache_store = :redis_cache_store, { url: 'redis://127.0.0.1:6379/0' }"
end

d('app/models', 'redis')
