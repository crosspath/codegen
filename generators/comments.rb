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
      "# Windows does not include zoneinfo files, so bundle "\
          "the tzinfo-data gem\n"
    ]
  )

  remove_strings(
    'config/application.rb',
    [
      "# Require the gems listed in Gemfile, including any gems\n"\
          "# you've limited to :test, :development, or :production.\n",
      "    # Initialize configuration defaults for originally generated "\
          "Rails version.\n",
      "\n\s*# Settings in config.+ any gems in your application.\n"
    ]
  )

  remove_strings(
    'config/puma.rb',
    [
      "# Specifies the `port` that Puma will listen on to receive requests; "\
          "default is 3000.\n#\n",
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

  replace_strings(
    'test/test_helper.rb',
    {
      from:
          "  # Setup all fixtures in test/fixtures/\*.yml for all tests in "\
          "alphabetical order.",
      to:
          "  # Setup all fixtures in test/fixtures/*.yml for all tests in\n"\
          "  # alphabetical order."
    }
  )

  replace_strings(
    'app/jobs/application_job.rb',
    {
      from:
          "  # Most jobs are safe to ignore if the underlying records are no "\
          "longer available",
      to:
          "  # Most jobs are safe to ignore if the underlying records are\n"\
          "  # no longer available"
    }
  )

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
          "  # Ensures that a master key has been made available in either "\
          "ENV\[\"RAILS_MASTER_KEY\"\]\n"\
          "  # or in config/master.key. This key is used to decrypt "\
          "credentials (and other encrypted files).",
      to:
          "  # Ensures that a master key has been made available in either\n"\
          "  # ENV[\"RAILS_MASTER_KEY\"] or in config/master.key.\n"\
          "  # This key is used to decrypt credentials (and other encrypted "\
          "files)."
    }
  )

  replace_strings(
    'config/environments/production.rb',
    {
      from:
          "  # Force all access to the app over SSL, use "\
          "Strict-Transport-Security, and use secure cookies.",
      to:
          "  # Force all access to the app over SSL, use "\
          "Strict-Transport-Security,\n"\
          "  # and use secure cookies."
    }
  )

  replace_strings(
    'config/environments/production.rb',
    {
      from:
          "  # Use a real queuing backend for Active Job (and separate queues "\
          "per environment).",
      to:
          "  # Use a real queuing backend for Active Job (and separate\n"\
          "  # queues per environment)."
    }
  )

  replace_strings(
    'config/environments/production.rb',
    {
      from:
          "  # config.logger = ActiveSupport::TaggedLogging.new("\
          "Syslog::Logger.new 'app-name')",
      to:
          "  # config.logger = ActiveSupport::TaggedLogging.new(\n"\
          "  #   Syslog::Logger.new 'app-name'\n  # )"
    }
  )

  replace_strings(
    'config/environments/production.rb',
    {
      from:
          "  # config.active_record.database_resolver = "\
          "ActiveRecord::Middleware::DatabaseSelector::Resolver\n"\
          "  # config.active_record.database_resolver_context = "\
          "ActiveRecord::Middleware::DatabaseSelector::Resolver::Session",
      to:
          "  # config.active_record.database_resolver =\n"\
          "  #   ActiveRecord::Middleware::DatabaseSelector::Resolver\n"\
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
        "# You can also remove all the silencers if you're trying to debug "\
        "a problem\n"\
        "# that might stem from framework code."
    }
  )

  replace_strings(
    'config/initializers/content_security_policy.rb',
    {
      from:
          "# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/"\
          "Content-Security-Policy",
      to:
        "# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/\n"\
        "#         Content-Security-Policy"
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
        "#     policy.connect_src(\n"\
        "#       :self, :https, \"http://localhost:3035\", "\
        "\"ws://localhost:3035\"\n"\
        "#     )\n"\
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
          "# Rails.application.config."\
          "content_security_policy_nonce_generator =\n"\
          "#   -> request { SecureRandom.base64(16) }"
    }
  )

  replace_strings(
    'config/initializers/content_security_policy.rb',
    {
      from:
          "# Rails.application.config."\
          "content_security_policy_nonce_directives = %w(script-src)",
      to:
          "# Rails.application.config."\
          "content_security_policy_nonce_directives = %w(\n"\
          "#   script-src\n"\
          "# )"
    }
  )

  replace_strings(
    'config/initializers/content_security_policy.rb',
    {
      from:
          "# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/"\
          "Content-Security-Policy-Report-Only",
      to:
        "# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/\n"\
        "#         Content-Security-Policy-Report-Only"
    }
  )

  replace_strings(
    'config/initializers/wrap_parameters.rb',
    {
      from:
          "# Enable parameter wrapping for JSON. "\
          "You can disable this by setting :format to an empty array.",
      to:
        "# Enable parameter wrapping for JSON.\n"\
        "# You can disable this by setting :format to an empty array."
    }
  )
end
