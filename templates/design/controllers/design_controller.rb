class DesignController < ApplicationController
  def show
    layout   = params[:layout].to_s
    template = "design/#{layout}/#{params[:id]}"
    path     = File.join('app/views', template)

    if layout.empty? || template.include?('..') || Dir["#{path}.*"].empty?
      head :not_found
    else
      render template, layout: layout
    end
  end
end
