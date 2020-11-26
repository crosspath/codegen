$main ||= self

require_relative 'functions.rb'
require_relative 'generator.rb'

Dir['#{__dir__}/generators/*.rb'].each do |file|
  require file
end

answers = {}
options = {all: 'All', cfg: 'Configurate', no: 'Nothing'}

answers[:slim] = $main.yes?('Use Slim templates? (y/n)')

answers[:base] = $main.yes?('Add all base files? (y/n)')

# Для разработчиков параметры доступа к базе данных (DATABASE_URL) будут
# храниться в файлах .env.*.local.
# Эти файлы не должны попасть в репозиторий.
# Этот параметр можно также использовать на сервере.
answers[:db] = $main.yes?('Use ENV[DATABASE_URL] for production? (y/n)')
unless answers[:db]
  answers[:db_name] = $main.ask('Database name for production =')
  puts('-' * 8)
end

answers[:product] = $main.yes?('Add README & docs? (y/n)')
if answers[:product]
  answers[:product_name]  = $main.ask('Product name (for Readme) =')
  answers[:product_specs] = $main.yes?('Add templates for specs? (y/n)')
  puts('-' * 8)
end

answers[:webpack] =
    $main.send(:webpack_install?) || $main.yes?('Add Webpack? (y/n)')

answers[:design] = $main.yes?('Add tools for design? (y/n)')
if answers[:design]
  answers[:design_bootstrap] = $main.yes?('Use Bootstrap UI? (y/n)')
  puts('-' * 8)
end

answers[:mail] =
  !$main.options[:skip_action_mailer] ||
  $main.yes?('Add config for ActionMailer? (y/n)')

answers[:sorcery] = $main.yes?('Add Sorcery? (y/n)')

answers[:sidekiq] = $main.yes?('Add Sidekiq? (y/n)')
answers[:redis]   = answers[:sidekiq] || $main.yes?('Add Redis? (y/n)')
if answers[:redis]
  answers[:redis_model] = $main.yes?('Add RedisModel? (y/n)')
  puts('-' * 8)
end

answers[:test] = $main.yes?('Add gems for testing? (y/n)')

answers[:svelte] = $main.yes?('Add Svelte? (y/n)')

answers[:vue] = $main.yes?('Add Vue? (y/n)')
if answers[:vue]
  answers[:vue_formulate] = $main.yes?('Add Vue-Formulate? (y/n)')
  answers[:vue_pug]       = $main.yes?('Add Pug? (y/n)')
  puts('-' * 8)
end

answers[:capistrano] = $main.yes?('Add Capistrano? (y/n)')

Generator.run_all(answers)
