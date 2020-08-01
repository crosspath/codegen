$main.gem 'sorcery'

$main.append_to_file('db/seeds.rb') do
  <<-LINE
User.find_or_create_by!(
  login:    'admin@localhost',
  password: 'password'
)
  LINE
end

after_bundle_install do
  $main.generate('sorcery:install', 'reset_password', 'brute_force_protection')

  d('app/controllers', 'sorcery/controllers', recursive: true)

  f('app/mailers/user_mailer.rb', 'sorcery/mailers/user_mailer.rb')

  f('app/models/user.rb', 'sorcery/models/user.rb')

  d('app/views', 'sorcery/views', recursive: true)

  $main.route <<-END
  scope module: :users do
    resource :session, path: 'auth', only: [:show, :create, :destroy]
    resource :reset_password, path: 'reset-password', only: [:show, :create]
    resource :change_password, path: 'change-password', only: [:show, :create]
    resource :unlock, only: [:show]
  end
  END

  $main.route "root to: 'welcome#index'"

  d('config/locales', 'sorcery/locales')
  d('app/forms', 'sorcery/forms', recursive: true)

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

  $main.gsub_file(
    'config/initializers/sorcery.rb',
    /(?:\#\s)?user.consecutive_login_retries_amount_limit =[^\n]*/,
    'user.consecutive_login_retries_amount_limit = 7'
  )

  puts 'Sorcery installed'
end
