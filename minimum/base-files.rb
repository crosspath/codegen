$main.append_to_file(
  '.gitignore',
  <<-LINE

*.local
.DS_Store
.directory
Thumbs.db
[Dd]esktop.ini
~$*

/vendor/*
!/vendor/.keep
  LINE
)

d('', 'base-files')
d('bin', 'base-files/bin')

$main.run('chmod +x bin/configs bin/setup')

d('app/forms', 'base-files/forms')
d('app/presenters', 'base-files/presenters')
d('app/queries', 'base-files/queries')

$main.inject_into_file(
  'app/controllers/application_controller.rb',
  before: "\nend"
) do
  <<-END.rstrip

  def with_form(form)
    if form.success
      yield form
    else
      render json: { errors: form.errors }, status: 422
    end
  end

  def render_json_errors(errors)
    render json: { errors: errors }, status: 422
  end
  END
end

$main.inject_into_file(
  'app/views/layouts/application.html.erb',
  before: '    <%= csrf_meta_tags %>'
) do
  <<-END
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
  END
end

$main.inject_into_file(
  'app/views/layouts/application.html.erb',
  "\n    <%= AlertsPresenter.flashes(self) %>",
  after: '<body>'
)

erb(
  'app/views/layouts/application.html.slim',
  'base-files/layouts/application.html.slim.erb',
  skip_turbolinks: $main.options[:skip_turbolinks]
)

$main.create_file('app/assets/stylesheets/application.scss') do
  existing = File.read('app/assets/stylesheets/application.css')
  requires = []

  existing.gsub!(%r{/\*(.*)\*/}m) do |match|
    match.split("\n").each do |x|
      res = x.match(/=\s*(require_.+)\Z/)
      requires << res[1] if res
    end
    ''
  end
  existing.strip!
  header = requires.map { |x| "//= #{x}\n" }

  [header, (existing.empty? ? '' : "\n"), existing].join
end

$main.remove_file('app/assets/stylesheets/application.css')
