module Users
  class ChangePasswordsController < ApplicationController
    def create
      with_form(try_to_change_password) do |result|
        render json: { notice: result.errors }
      end
    end

    private

    def try_to_change_password
      result = UserAuth.find_by_token(params)
      result = UserAuth.change_password(result.object, params) if result.success

      result
    end
  end
end
