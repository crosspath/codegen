def design_base
  $main.route <<-END
    if Rails.env.development?
      get 'design/:layout/*id' => 'design#show'
    end
  END

  $main.create_file('app/assets/stylesheets/pages/.keep', '')
  $main.create_file('app/assets/stylesheets/_colors.scss', "$azure: azure;\n")

  d('app/controllers', 'design/controllers')
  d('app/presenters', 'design/presenters')
  d('app/views', 'design/views', recursive: true)
end

def design_bootstrap
  $main.run 'yarn add bootstrap'

  d('app/assets/stylesheets', 'design/stylesheets/bootstrap')
end

def design_flash(answers)
  erb(
    'app/assets/stylesheets/components/flash.scss',
    'design/stylesheets/components/flash.scss.erb',
    use_bootstrap: answers[:design_bootstrap]
  )
end

Generator.add_actions do |answers|
  next unless answers[:design]

  design_base
  design_bootstrap if answers[:design_bootstrap]
  design_flash(answers)
end
