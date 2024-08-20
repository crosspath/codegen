Generator.add_actions do |answers|
  next unless answers[:sidekiq]

  $main.gem 'sidekiq'

  $main.inject_into_file(
    'config/application.rb',
    "    config.active_job.queue_adapter = :sidekiq\n",
    before: "  end\nend\n"
  )

  templates = File.join(__dir__, '..', 'templates', 'sidekiq')

  $main.initializer(
    'sidekiq.rb',
    File.read(File.join(templates, 'initializer.rb'))
  )
  f('config/sidekiq.yml', 'sidekiq/config.yml')

  $main.prepend_to_file('config/routes.rb', "require 'sidekiq/web'\n\n")

  $main.route <<-END
    is_admin = ->(rq) do
      user = User.find_by(id: rq.session[:user_id])
      user && !user.login_locked?
    end

    constraints(is_admin) do
      mount Sidekiq::Web, at: '/sidekiq'
    end
  END
end
