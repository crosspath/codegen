$main ||= self

require_relative 'functions.rb'
require_relative 'js/xhr.rb'

# run 'yarn add vue vue-loader vue-template-compiler'

rails_command 'webpacker:install:vue'

inject_into_file(
  'config/webpack/environment.js',
  before: "const webpack = require('webpack')"
) do
  <<-LINE
const pug = require('./loaders/pug')

  LINE
end

inject_into_file(
  'config/webpack/environment.js',
  before: "environment.loaders.prepend('vue', vue)"
) do
  <<-LINE
environment.loaders.prepend('pug', pug)

  LINE
end

d('app/javascript/lib', 'js/lib')
f('config/webpack/loaders/pug.js', 'js/pug.js')

append_to_file('app/javascript/packs/application.js') do
  <<-LINE
import 'lib/vue';
import 'lib/xhr';
  LINE
end

run 'yarn add @braid/vue-formulate'
run 'yarn add pug pug-plain-loader vue-i18n vue-multiselect'

inject_into_file(
  'app/presenters/base_presenter.rb',
  after: "\n  end\n"
) do
  <<-LINE

  def vue_tag(tag:, attrs: {}, vars: {})
    vars    = vars.map { |k, v| [":#{k}", v.to_json] }.to_h
    options = {vue: ''}.merge(attrs, vars)

    @vh.content_tag(tag, '', options)
  end
  LINE
end

append_to_file('app/assets/stylesheets/application.scss') do
  <<-LINE
@import "vue-multiselect/dist/vue-multiselect.min";
  LINE
end

create_file('app/views/design/vue-example.html.slim') do
  <<-LINE
example-component :example-object='{"id": 1, "name": 'test'}'
  LINE
end

d('app/javascript/components', 'templates/vue/components', recursive: true)

if yes?('Добавить стили, адаптирующие Vue-Formulate к Bootstrap? (y/n)')
  d('app/assets/stylesheets/components', 'vue/stylesheets')
end
