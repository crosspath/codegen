class DesignController < ApplicationController
  def show
    template = "design/#{params[:id]}"
    path     = File.join('app/views', template)

    if template.include?('..') || Dir["#{path}.*"].empty?
      head :not_found
    else
      render template
    end
  end
end
