class Users::UnlocksController < ApplicationController
  before_action :redirect_if_logged

  def show
    token = params[:token]
    if token.present?
      user = User.load_from_unlock_token(token)
      if user
        if user.login_locked?
          if user.login_unlock!
            flash[:notice] = t("users/unlock.unlocked", email: user.email)
          else
            flash[:alert] = user.error_messages
          end
        else
          flash[:notice] = t("users/unlock.not_locked", email: user.email)
        end
      else
        flash[:alert] = t("users/unlock.not_found")
      end
    else
      flash[:alert] = t("users/unlock.no_token")
    end
    redirect_to session_path
  end

  protected

  def redirect_if_logged
    redirect_to admin_path if logged_in?
  end
end
