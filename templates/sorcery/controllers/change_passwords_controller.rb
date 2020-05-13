class Users::ChangePasswordsController < ApplicationController
  def show
    token = params[:token]
    if token.present?
      @user = User.load_from_reset_password_token(token)
    elsif current_user
      @user = current_user
    else
      flash[:notice] = t('users/change_password.no_token')
      redirect_to reset_password_path
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

    password = params[:password]
    confirm  = params[:password_confirmation]

    if @user
      if password == confirm
        if @user.change_password(password)
          session.delete(:user_email)
          flash[:notice] = t("users/change_password.changed")
          redirect_to(logged_in? ? admin_path : session_path)
        else
          flash.now[:alert] = @user.error_messages
          render :show
        end
      else
        flash.now[:alert] = t("users/change_password.not_match")
        render :show
      end
    else
      flash.now[:alert] = t("users/change_password.not_found")
      render :show
    end
  end
end
