# frozen_string_literal: true

MultiSessions.configure do |config|
  # Default: %i[cookie jwt generate_session_id]
  config.auth_strategies = %i[jwt generate_session_id].freeze

  # Default: true. You may read values from ENV or another configuration source.
  config.cookies_options[:secure] = ENV.fetch("ENABLE_HTTPS", "false") == "true"

  # Default: "1234567890"
  config.jwt_options[:secret_key] = ENV.fetch("JWT_SECRET_KEY", "1234567890")

  # Default: :current_user_token
  config.permanent_cookie_name = :current_user_token

  # Default: :session_token
  config.session_cookie_name = :session_token

  # Default value is not set, you should pass class that behaves like ActiveRecord::Base.
  config.session_model_class = -> { Session }

  # Default value is not set, you should pass instance of ActiveRecord::Relation or
  # descendant class of ActiveRecord::Base.
  config.user_model_scope = -> { Account.users }
end

if Rails.env.development?
  ActiveSupport::Reloader.to_prepare do
    # Here "Account" is your model class (e.g. derived from ActiveRecord::Base) and "admin?" is
    # redefined method in "Account" class.
    MultiSessions::MockCurrent.user_model_class =
      Class.new(Account) do
        def admin?
          true
        end
      end
  end
end
