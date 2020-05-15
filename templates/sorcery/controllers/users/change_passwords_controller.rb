class Users::ChangePasswordsController < ApplicationController
  def show
    token = params[:token]
    if token.present?
      @user = User.load_from_reset_password_token(token)
    elsif current_user
      @user = current_user
    else
      flash[:notice] = t('users/change_password.no_token')
      return redirect_to reset_password_path
    end

    if @user
      session[:user_email] = @user.email
    else
      flash[:alert] = t('users/change_password.token_expired')
      redirect_to reset_password_path
    end
  end

  def create
    @user = User.find_by(email: session[:user_email])

    form = Users::ChangePasswordForm.update(@user, params)
    if form.success
      session.delete(:user_email)
      flash[:notice] = form.messages
      redirect_to(logged_in? ? root_path : session_path)
    else
      flash.now[:alert] = form.messages
      render :show
    end
  end
end
