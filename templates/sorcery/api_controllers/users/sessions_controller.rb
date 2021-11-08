class Users::SessionsController < ApplicationController
  def create
    reason = nil

    login(params[:email], params[:password]) do |_user, failure_reason|
      reason = failure_reason
    end

    if current_user
      render json: {}
    else
      render_json_errors([t("users/session.#{reason}")])
    end
  end

  def destroy
    logout

    render json: {}
  end
end
