class Users::ResetPasswordsController < ApplicationController
  before_action :redirect_if_logged

  def show; end

  def create
    @email = params[:email]
    user  = User.find_by(email: @email)

    if user
      if user.deliver_reset_password_instructions!
        flash[:notice] = t("users/reset_password.email_sent", email: @email)
        redirect_to session_path
      else
        flash[:alert] = t("users/reset_password.too_often", email: @email)
        redirect_to reset_password_path
      end
    else
      flash.now[:alert] = t("users/reset_password.not_found")
      render :show
    end
  end

  protected

  def redirect_if_logged
    redirect_to admin_path if logged_in?
  end
end
