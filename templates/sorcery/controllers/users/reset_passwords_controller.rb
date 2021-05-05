class Users::ResetPasswordsController < ApplicationController
  before_action :redirect_if_logged

  def show; end

  def create
    result   = UserAuthForm.reset_password(params)
    messages = result.errors

    case result.success
    when :email_sent
      redirect_to session_path, notice: messages
    when :too_often
      redirect_to reset_password_path, alert: messages
    when :not_found
      # flash.now[:alert] = messages
      @email = params[:email]
      render :show, alert: messages
    end
  end

  protected

  def redirect_if_logged
    redirect_to root_path if logged_in?
  end
end
