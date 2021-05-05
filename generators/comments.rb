Generator.add_actions do |answers|
  remove_strings(
    'Gemfile',
    [
      "# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'\n",
      "# Use Active Model has_secure_password\n",
      "# gem 'bcrypt', '~> 3.1.7'\n",
      "# Use Active Storage variant\n",
      "# gem 'image_processing', '~> 1.2'\n",
      "# Reduces boot times through caching; required in config/boot.rb\n",
      "  # Spring speeds up development by keeping your application running "\
          "in the background. Read more: https://github.com/rails/spring\n",
      "# Windows does not include zoneinfo files, so bundle the tzinfo-data gem\n"
    ]
  )

  remove_strings(
    'config/application.rb',
    [
      "# Require the gems listed in Gemfile, including any gems\n"\
          "# you've limited to :test, :development, or :production.\n",
      "    # Initialize configuration defaults for originally generated Rails version.\n",
      "\n\s*# Settings in config.+ any gems in your application.\n"
    ]
  )

  remove_strings(
    'config/puma.rb',
    [
      "# Specifies the `port` that Puma will listen on to receive requests; default is 3000.\n#\n",
      "\n# Specifies the `environment` that Puma will run in.\n#\n"
    ]
  )

  remove_strings(
    'config/routes.rb',
    [
      "  # For details on the DSL available within this file, see "\
          "https://guides.rubyonrails.org/routing.html\n"
    ]
  )

  remove_strings('db/seeds.rb', ["#[^\n]*\n"])
  if File.read('db/seeds.rb').strip.empty?
    $main.append_to_file('db/seeds.rb', "# db/seeds.rb\n")
  end

  env_string =
      "[\s\n]*# Settings specified here will take precedence over those "\
      "in config/application.rb.\n\s*"

  %w[development test production].each do |key|
    remove_strings("config/environments/#{key}.rb", [env_string])
  end

  replace_strings(
    'config/environments/production.rb',
    {
      from:
          "  # config.active_record.database_resolver = "\
          "ActiveRecord::Middleware::DatabaseSelector::Resolver",
      to:
          "  # config.active_record.database_resolver =\n"\
          "  #   ActiveRecord::Middleware::DatabaseSelector::Resolver"
    }
  )

  replace_strings(
    'config/environments/production.rb',
    {
      from:
          "  # config.active_record.database_resolver_context = "\
          "ActiveRecord::Middleware::DatabaseSelector::Resolver::Session",
      to:
          "  # config.active_record.database_resolver_context =\n"\
          "  #   ActiveRecord::Middleware::DatabaseSelector::Resolver::Session"
    }
  )

  replace_strings(
    'config/initializers/backtrace_silencers.rb',
    {
      from:
          "# You can add backtrace silencers for libraries that you're using "\
          "but don't wish to see in your backtraces.",
      to:
          "# You can add backtrace silencers for libraries that you're using\n"\
          "# but don't wish to see in your backtraces."
    }
  )

  replace_strings(
    'config/initializers/backtrace_silencers.rb',
    {
      from:
          "# You can also remove all the silencers if you're trying to debug "\
          "a problem that might stem from framework code.",
      to:
        "# You can also remove all the silencers if you're trying to debug a problem\n"\
        "# that might stem from framework code."
    }
  )

  replace_strings(
    'config/initializers/content_security_policy.rb',
    {
      from:
          "#   policy.connect_src :self, :https, \"http://localhost:3035\", "\
          "\"ws://localhost:3035\" if Rails.env.development?",
      to:
        "#   if Rails.env.development?\n"\
        "#     policy.connect_src(:self, :https, \"http://localhost:3035\", "\
        "\"ws://localhost:3035\")\n"\
        "#   end"
    }
  )

  replace_strings(
    'config/initializers/content_security_policy.rb',
    {
      from:
          "# Rails.application.config.content_security_policy_nonce_generator"\
          " = -> request { SecureRandom.base64(16) }",
      to:
          "# Rails.application.config.content_security_policy_nonce_generator =\n"\
          "#   -> request { SecureRandom.base64(16) }"
    }
  )
end
