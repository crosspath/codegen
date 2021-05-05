module UserAuthForm
  extend BaseForm

  undefine_form_methods :create, :update, :destroy

  def self.find_by_token(params, user = nil)
    token = params[:token]
    user  = User.load_from_reset_password_token(token) if token.present?

    if user
      success(user)
    else
      key = token.blank? ? 'no_token' : 'token_expired'
      failure(nil, msg("change_password.#{key}"))
    end
  end

  def self.change_password(object, params)
    return failure(object, msg('change_password.not_found')) unless object

    password = params[:password]
    confirm  = params[:password_confirmation]

    if password == confirm
      if object.change_password(password)
        success(object, msg('change_password.changed'))
      else
        failure(object)
      end
    else
      failure(object, msg('change_password.not_match'))
    end
  end

  def self.reset_password(params)
    email = params[:email]
    user  = User.find_by(email: email)

    if user
      key = user.deliver_reset_password_instructions! ? :email_sent : :too_often
      result(key, user, msg("reset_password.#{key}", email: @email))
    else
      result(:not_found, nil, msg('reset_password.not_found'))
    end
  end

  def self.unlock(params)
    token = params[:token]
    return failure(nil, msg('unlock.no_token')) if token.blank?

    user = User.load_from_unlock_token(token)

    return failure(user, msg('unlock.not_found')) unless user

    if user.login_locked?
      if user.login_unlock!
        success(user, msg('unlock.unlocked', email: user.email))
      else
        failure(user)
      end
    else
      success(user, msg('unlock.not_locked', email: user.email))
    end
  end

  def self.msg(key, **kwargs)
    [I18n.t("users/#{key}", **kwargs)]
  end
  private_class_method :msg
end
