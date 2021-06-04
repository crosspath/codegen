def mail_production
  $main.environment(nil, env: 'production') do
    <<-END
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method       = :smtp
  config.action_mailer.perform_deliveries    = true
  config.action_mailer.asset_host            = ENV['ASSET_HOST']
  config.action_mailer.default_url_options = {
    host: ENV['MAILER_HOST'],
    from: ENV['MAILER_SENDER']
  }
  config.action_mailer.smtp_settings = {
    address:              ENV['SMTP_HOST'],
    port:                 465,
    domain:               ENV['SMTP_DOMAIN'],
    authentication:       'plain',
    user_name:            ENV['SMTP_USER'],
    password:             ENV['SMTP_PASSWORD'],
    enable_starttls_auto: true,
    tls:                  true
  }
    END
  end
end

def mail_development
  $main.environment(nil, env: 'development') do
    <<-END
  config.action_mailer.delivery_method = :file
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = {
    host: ENV['MAILER_HOST'],
    from: ENV['MAILER_SENDER']
  }
    END
  end
end

def mail_test
  $main.environment(nil, env: 'test') do
    <<-END
  config.action_mailer.default_url_options = {
    host: ENV['MAILER_HOST'],
    from: ENV['MAILER_SENDER']
  }
    END
  end
end

def mail_dotenv
  mailer_constants =
      "MAILER_HOST=localhost:3000\nMAILER_SENDER=admin@localhost\n"

  %w[.env.development .env.test].each do |env_name|
    $main.append_to_file(env_name, mailer_constants)
  end

  $main.append_to_file(
    '.env.production',
    mailer_constants + <<-END
ASSET_HOST=http://localhost:3000
SMTP_HOST=smtp.yandex.ru
SMTP_DOMAIN=yandex.ru
SMTP_USER=admin@localhost
SMTP_PASSWORD=mypassword
END
  )
end

Generator.add_actions do |answers|
  next unless answers[:mail]

  mail_production
  mail_development
  mail_test
  mail_dotenv
end
