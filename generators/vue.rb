def vue_presenter
  file = 'app/presenters/base_presenter.rb'
  unless File.writable?(file)
    puts "Skip, #{file} is not writable"
    return
  end

  $main.inject_into_file(file, after: "\n  end\n") do
    <<-LINE

  def vue_tag(tag:, attrs: {}, vars: {})
    vars    = vars.map { |k, v| [":\#{k}", v.to_json] }.to_h
    options = {vue: ''}.merge(attrs, vars)

    @vh.content_tag(tag, '', options)
  end
    LINE
  end
end

def vue_packages(answers)
  $main.rails_command 'webpacker:install:vue'

  $main.append_to_file('app/javascript/packs/application.js') do
    "import '../lib/vue';\n"
  end

  packages = ['vue-i18n', 'vue-multiselect']
  packages << '@braid/vue-formulate' if answers[:vue_formulate]
  packages += ['pug', 'pug-plain-loader'] if answers[:vue_pug]

  add_npm_package(*packages)
end

def vue_files(answers)
  $main.append_to_file("#{css_dir(answers)}/application.scss") do
    lines = ["@import 'vue-multiselect/dist/vue-multiselect.min.css';\n"]
    lines << "@import './_formulate.scss';\n" if answers[:vue_formulate]
    lines.join
  end

  d('app/javascript/lib', 'vue/lib')
  d('app/javascript/components', 'vue/components', recursive: true)

  if answers[:slim]
    $main.create_file('app/views/design/application/vue-example.slim') do
      <<-LINE
example-component (vue :example-object='{"id": 1, "name": "test"}')
      LINE
    end
  else
    $main.create_file('app/views/design/application/vue-example.html.erb') do
      <<-LINE
<example-component vue :example-object='{"id": 1, "name": "test"}'/>
      LINE
    end
  end

  # Добавить стили, адаптирующие Vue-Formulate к Bootstrap
  if answers[:design_bootstrap] && answers[:vue_formulate]
    d(css_dir(answers), 'vue/stylesheets')
  end
end

def vue_pug
  $main.inject_into_file(
    'config/webpack/environment.js',
    "\nconst pug = require('./loaders/pug')",
    before: "\n\n"
  )

  $main.inject_into_file(
    'config/webpack/environment.js',
    "environment.loaders.prepend('pug', pug)\n",
    before: "environment.loaders.prepend('vue', vue)\n"
  )

  f('config/webpack/loaders/pug.js', 'vue/pug.js')
end

Generator.add_actions do |answers|
  next unless answers[:vue]

  require_relative '../js/xhr.rb'

  vue_presenter

  after_bundle_install do
    vue_packages(answers)
    vue_files(answers)
    vue_pug if answers[:vue_pug]
  end
end
