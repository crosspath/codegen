module Users
  class SessionsController < ApplicationController
    def create
      reason = nil

      login(params[:email], params[:password]) do |_user, failure_reason|
        reason = failure_reason
      end

      if current_user
        render json: current_user
      else
        render_json_errors([t("users/session.#{reason}")])
      end
    end

    def destroy
      logout

      render json: {}
    end

    def show
      if current_user
        render json: current_user
      else
        not_authenticated
      end
    end
  end
end
