module ColorsPresenter
  module_function

  FILE_PATH = 'app/assets/stylesheets/_colors.scss'

  def colors
    lines = File.readlines(Rails.root.join(FILE_PATH))

    lines.map do |line|
      if line.starts_with?('//') || line.strip.empty?
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
