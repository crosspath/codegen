$main.gem 'sorcery'

$main.send(:after_bundle) do
  $main.generate('sorcery:install', 'reset_password', 'brute_force_protection')

  d('app/controllers/users', 'sorcery/controllers')

  f('app/mailers/user_mailer.rb', 'sorcery/mailers/user_mailer.rb')

  f('app/models/user.rb', 'sorcery/models/user.rb')

  d('app/views/users', 'sorcery/views/users')
  d('app/views/user_mailer', 'sorcery/views/user_mailer')

  $main.route <<-END
  scope module: :users do
    resource :session, path: 'auth', only: [:show, :create, :destroy]
    resource :reset_password, path: 'reset-password', only: [:show, :create]
    resource :change_password, path: 'change-password', only: [:show, :create]
    resource :unlock, only: [:show]
  end
  END

  d('config/locales', 'sorcery/locales')

  puts 'Sorcery installed'
end
