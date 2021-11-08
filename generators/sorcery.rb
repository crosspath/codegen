def sorcery_seeds
  $main.append_to_file('db/seeds.rb') do
    <<-LINE
User.find_or_initialize_by(email: 'admin@localhost').tap do |u|
  u.password = 'password'
  u.save!
end
    LINE
  end
end

def sorcery_base(answers)
  $main.generate('sorcery:install', 'reset_password', 'brute_force_protection')

  f('app/models/user.rb', 'sorcery/models/user.rb')

  d('config/locales', 'sorcery/locales')
  d('app/services', 'sorcery/services', recursive: true)

  $main.gsub_file(
    'config/initializers/sorcery.rb',
    /(?:\#\s)?user.consecutive_login_retries_amount_limit =[^\n]*/,
    'user.consecutive_login_retries_amount_limit = 7'
  )

  if answers[:mail]
    f('app/mailers/user_mailer.rb', 'sorcery/mailers/user_mailer.rb')
  end

  if answers[:mail]
    if answers[:slim]
      d('app/views', 'sorcery/mailer_views/slim', recursive: true)
    else
      d('app/views', 'sorcery/mailer_views/erb', recursive: true)
    end

    $main.gsub_file(
      'config/initializers/sorcery.rb',
      /(?:\#\s)?user.unlock_token_mailer =[^\n]*/,
      'user.unlock_token_mailer = UserMailer'
    )

    $main.gsub_file(
      'config/initializers/sorcery.rb',
      /(?:\#\s)?user.reset_password_mailer =[^\n]*/,
      'user.reset_password_mailer = UserMailer'
    )
  end

  if $main.options[:api]
    d('app/controllers', 'sorcery/api_controllers', recursive: true)

    $main.route <<-END
    scope module: :users do
      resource :change_password, path: 'change-password', only: [:create]
      resource :reset_password, path: 'reset-password', only: [:create]
      resource :session, path: 'auth', only: [:create, :destroy]
      resource :unlock, only: [:create]
    end
    END
  else
    d('app/controllers', 'sorcery/controllers', recursive: true)

    if answers[:slim]
      d('app/views', 'sorcery/views/slim', recursive: true)
    else
      d('app/views', 'sorcery/views/erb', recursive: true)
    end

    $main.route <<-END
    scope module: :users do
      resource :change_password, path: 'change-password', only: [:show, :create]
      resource :reset_password, path: 'reset-password', only: [:show, :create]
      resource :session, path: 'auth', only: [:show, :create, :destroy]
      resource :unlock, only: [:show]
    end
    END

    $main.route "root to: 'welcome#index'"
  end

  puts 'Sorcery installed'
end

Generator.add_actions do |answers|
  next unless answers[:sorcery]

  $main.gem 'sorcery'
  sorcery_seeds

  after_bundle_install do
    sorcery_base(answers)
  end
end
