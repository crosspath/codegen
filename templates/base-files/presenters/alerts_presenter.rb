module AlertsPresenter
  module_function

  # @param object ActiveRecord::Base
  def model_errors(object)
    vh = ApplicationController.helpers

    return '' if object.errors.blank?

    vh.content_tag('ul', class: 'model-errors') do
      object.errors.map do |key, message|
        if key == :base
          vh.content_tag('li', message)
        else
          title = object.class.human_attribute_name(key)
          vh.content_tag('li') do
            [
              vh.content_tag('span', title),
              vh.content_tag('ul', vh.content_tag('li', message))
            ].join.html_safe
          end
        end
      end.join.html_safe
    end
  end

  # @param vh ActionView::Base
  #
  def flashes(vh)
    flash = vh.flash

    return '' if flash.blank?

    flash.map do |key, messages|
      Array.wrap(messages).map do |msg|
        vh.content_tag('div', msg, class: "flash-message--#{key}")
      end.join.html_safe
    end.join.html_safe
  end
end
