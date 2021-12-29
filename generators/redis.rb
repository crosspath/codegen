Generator.add_actions do |answers|
  next unless answers[:redis]

  $main.gem 'redis'

  $main.environment(nil, env: 'production') do
    "config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }"
  end

  $main.append_to_file('.env', "REDIS_URL=redis://localhost:6379/0\n")
end
