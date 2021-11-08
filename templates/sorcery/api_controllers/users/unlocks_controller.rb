class Users::UnlocksController < ApplicationController
  def show
    with_form UserAuth.unlock(params) do |result|
      render json: { notice: result.errors }
    end
  end
end
