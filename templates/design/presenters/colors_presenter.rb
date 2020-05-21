module ColorsPresenter
  module_function

  def colors
    lines = File.readlines(Rails.root.join('app/assets/stylesheets/colors.scss'))

    lines.map do |line|
      if line.starts_with?('//')
        nil
      else
        line.chomp(";\n").split(':').map(&:strip)
      end
    end.compact
  end

  def cell(color, fg, bg)
    vh = ApplicationController.helpers

    vh.content_tag(
      :td,
      vh.content_tag(
        :div,
        color,
        class: 'color',
        style: "color: #{fg}; background-color: #{bg};"
      )
    )
  end
end
