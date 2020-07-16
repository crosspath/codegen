$main.route <<-END
  if Rails.env.development?
    get 'design/*id' => 'design#show'
  end
END

$main.create_file('app/assets/stylesheets/pages/.keep', '')
$main.create_file('app/assets/stylesheets/_colors.scss', "$azure: azure;\n")

use_bootstrap = $main.yes?('Использовать библиотеку Bootstrap? (y/n)')
if use_bootstrap
  $main.run 'yarn add bootstrap'

  d('app/assets/stylesheets', 'design/stylesheets/bootstrap')
end

erb(
  'app/assets/stylesheets/components/flash.scss',
  'design/stylesheets/components/flash.scss.erb',
  use_bootstrap: use_bootstrap
)

d('app/controllers', 'design/controllers')
d('app/presenters', 'design/presenters')
d('app/views', 'design/views', recursive: true)
