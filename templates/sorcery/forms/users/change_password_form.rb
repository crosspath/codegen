class Users::ChangePasswordForm < BaseForm
  class << self
    def update(object, params)
      success, message = check_params(object, params)

      self.new(success, object, Array.wrap(message))
    end

    private :create

    private

    def check_params(object, params)
      return [false, I18n.t('users/change_password.not_found')] unless object

      password = params[:password]
      confirm  = params[:password_confirmation]

      if password == confirm
        if object.change_password(password)
          [true, I18n.t('users/change_password.changed')]
        else
          [false, nil]
        end
      else
        [false, I18n.t('users/change_password.not_match')]
      end
    end
  end

  def initialize(success, object, messages = [])
    super(success, object)
    @messages = messages
  end

  def messages
    errors + @messages
  end
end
