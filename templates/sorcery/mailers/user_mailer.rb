class UserMailer < ApplicationMailer
  def send_unlock_token_email(user)
    @user = user
    mail(to: @user.email, subject: 'Учётная запись временно заблокирована')
  end

  def reset_password_email(user)
    @user = user
    mail(to: @user.email, subject: 'Сбросить пароль для учётной записи')
  end
end
