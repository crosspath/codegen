$main.route <<-END
  if Rails.env.development?
    get 'design/*id' => 'design#show'
  end
END

$main.file 'app/assets/stylesheets/components/.keep', ''
$main.file 'app/assets/stylesheets/pages/.keep', ''
$main.file 'app/assets/stylesheets/colors.scss', "$red: red;\n"

d('app/controllers', 'design/controllers')
d('app/assets/stylesheets/components', 'design/stylesheets')
d('app/views/common', 'design/views/common')
d('app/views/design', 'design/views/design')
