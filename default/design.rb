$main.route <<-END
  if Rails.env.development?
    get 'design/*id' => 'design#show'
  end
END

$main.create_file('app/assets/stylesheets/pages/.keep', '')
$main.create_file('app/assets/stylesheets/colors.scss', "$azure: azure;\n")

use_bootstrap = $main.yes?('Использовать библиотеку Bootstrap? (y/n)')
if use_bootstrap
  $main.run 'yarn add bootstrap'

  f(
    'app/assets/stylesheets/bootstrap-variables.scss',
    'design/stylesheets/bootstrap-variables.scss'
  )
end

erb(
  'app/assets/stylesheets/components/flash.scss',
  'design/stylesheets/components/flash.scss.erb',
  use_bootstrap: use_bootstrap
)

d('app/controllers', 'design/controllers')
d('app/views', 'design/views', recursive: true)
