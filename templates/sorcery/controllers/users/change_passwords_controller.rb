class Users::ChangePasswordsController < ApplicationController
  def show
    result = UserAuthForm.find_by_token(params, current_user)

    if result.success
      @user = result.object
      session[:user_email] = @user.email
    else
      redirect_to reset_password_path, notice: result.errors
    end
  end

  def create
    @user = User.find_by(email: session[:user_email])

    result = UserAuthForm.change_password(@user, params)
    if result.success
      session.delete(:user_email)
      redirect_to(logged_in? ? root_path : session_path, notice: result.errors)
    else
      render :show, alert: result.errors
    end
  end
end
