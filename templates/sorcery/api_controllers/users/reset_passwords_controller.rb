class Users::ResetPasswordsController < ApplicationController
  def create
    result   = UserAuth.reset_password(params)
    messages = result.errors

    case result.success
    when :email_sent
      render json: { notice: messages }
    when :too_often, :not_found
      render_json_messages(messages)
    end
  end
end
