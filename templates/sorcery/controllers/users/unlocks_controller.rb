class Users::UnlocksController < ApplicationController
  before_action :redirect_if_logged

  def show
    form = Users::UnlockForm.create(params)

    flash[form.success ? :notice : :alert] = form.messages

    redirect_to session_path
  end

  protected

  def redirect_if_logged
    redirect_to root_path if logged_in?
  end
end
