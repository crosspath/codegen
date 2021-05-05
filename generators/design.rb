def design_base(answers)
  $main.route <<-END
    if Rails.env.development?
      get 'design/:layout/*id' => 'design#show'
    end
  END

  dir = css_dir(answers)
  $main.create_file("#{dir}/pages/.keep", '')
  $main.create_file("#{dir}/_colors.scss", "$azure: azure;\n")

  d('app/controllers', 'design/controllers')
  d(dir, 'design/stylesheets')

  file_name = "colors.#{answers[:slim] ? 'slim' : 'html.erb'}"
  f("app/views/design/application/#{file_name}", "design/views/#{file_name}")

  erb(
    'app/presenters/colors_presenter.rb',
    'design/presenters/colors_presenter.rb.erb',
    css_dir: css_dir(answers)
  )
end

def design_bootstrap(answers)
  add_npm_package('bootstrap')

  d(css_dir(answers), 'design/stylesheets/bootstrap')
end

def design_flash(answers)
  erb(
    "#{css_dir(answers)}/components/flash.scss",
    'design/stylesheets/components/flash.scss.erb',
    use_bootstrap: answers[:design_bootstrap]
  )
end

Generator.add_actions do |answers|
  next unless answers[:design]

  design_base(answers)
  design_bootstrap(answers) if answers[:design_bootstrap]
  design_flash(answers)
end
