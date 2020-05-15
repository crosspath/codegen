class Users::SessionsController < ApplicationController
  before_action :redirect_if_logged, only: [:show, :create]

  def show; end

  def create
    @email = params[:email]
    reason = nil

    login(@email, params[:password]) do |user, failure_reason|
      reason = failure_reason
    end

    if current_user
      redirect_to root_path
    else
      flash.now[:alert] = t("users/session.#{reason}") if reason
      render :show
    end
  end

  def destroy
    logout

    redirect_to session_path
  end

  protected

  def redirect_if_logged
    redirect_to root_path if logged_in?
  end
end
