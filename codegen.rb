$main ||= self

require_relative 'functions.rb'
require_relative 'generator.rb'

Dir["#{__dir__}/generators/*.rb"].sort.each do |file|
  require file
end

answers = {}

answers[:spring] = $main.yes?('Add Spring preloader? (y/n)')

answers[:slim] = $main.yes?('Use Slim templates? (y/n)')

# TODO: GraphQL or RESTful

answers[:product] = $main.yes?('Add README & docs? (y/n)')
if answers[:product]
  answers[:product_name]  = $main.ask('> Product name (for Readme) =')
  answers[:product_specs] = $main.yes?('> Add templates for product specification? (y/n)')
end

# answers[:webpack] = !$main.options[:api]
answers[:webpack] = false # FIXME: temporarily disabled due to new front-end gems for Rails 7

answers[:design] = !$main.options[:api] && $main.yes?('Add tools for design? (y/n)')
if answers[:design]
  answers[:design_bootstrap] = $main.yes?('> Use Bootstrap UI? (y/n)')
end

answers[:mail] =
  !$main.options[:skip_action_mailer] && $main.yes?('Add settings & files for ActionMailer? (y/n)')

answers[:sorcery] = $main.yes?('Add Sorcery? (y/n)')

answers[:sidekiq] = !$main.options[:skip_active_job] && $main.yes?('Add Sidekiq? (y/n)')
answers[:redis]   = answers[:sidekiq] || $main.yes?('Add Redis? (y/n)')

if answers[:webpack]
  answers[:turbolinks] = $main.yes?('Add Turbolinks? (y/n)')
  answers[:svelte] = $main.yes?('Add Svelte? (y/n)')

  answers[:vue] = $main.yes?('Add Vue? (y/n)')
  if answers[:vue]
    answers[:vue_formulate] = $main.yes?('> Add Vue-Formulate? (y/n)')
    answers[:vue_pug]       = $main.yes?('> Add Pug? (y/n)')
  end

  answers[:axios] = (answers[:svelte] || answers[:vue]) && $main.yes?('Add Axios? (y/n)')
end

answers[:capistrano] = $main.yes?('Add Capistrano? (y/n)')

Generator.run_all(answers)
