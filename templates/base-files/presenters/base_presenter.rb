class BasePresenter
  attr_reader :obj, :vh, :rt

  def initialize(obj)
    @obj = obj
    @vh  = ApplicationController.helpers
    @rt  = Rails.application.routes.url_helpers
  end
end
