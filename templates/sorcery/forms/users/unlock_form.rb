class Users::UnlockForm < BaseForm
  class << self
    def create(params)
      user, success, message = check_token(params[:token])

      self.new(success, user, Array.wrap(message))
    end

    private :update

    private

    def check_token(token)
      return [User.new, false, I18n.t('users/unlock.no_token')] if token.blank?

      user = User.load_from_unlock_token(token)

      return [user, false, I18n.t('users/unlock.not_found')] unless user

      if user.login_locked?
        if user.login_unlock!
          [user, true, I18n.t('users/unlock.unlocked', email: user.email)]
        else
          [user, false, nil]
        end
      else
        [user, true, I18n.t('users/unlock.not_locked', email: user.email)]
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
