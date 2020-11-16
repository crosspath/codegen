$main ||= self

require_relative 'functions.rb'

gem 'sidekiq'

af('Procfile', "sidekiq:  bundle exec sidekiq\n")

inject_into_file(
  'config/application.rb',
  "    config.active_job.queue_adapter = :sidekiq\n",
  before: "  end\nend\n"
)

templates = File.join(__dir__, 'templates', 'sidekiq')

initializer 'sidekiq.rb', File.read(File.join(templates, 'initializer.rb'))
f('config/config.yml', 'sidekiq/config.yml')

inject_into_file(
  'config/routes.rb',
  "require 'sidekiq/web'\n\n",
  before: 'Rails.application.routes.draw do'
)
route <<-END
  constraints(->(rq) { User.find_by(id: rq.session[:user_id])&.admin? }) do
    mount Sidekiq::Web, at: '/sidekiq'
  end
END
