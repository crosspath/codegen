$main ||= self

require_relative 'functions.rb'
require_relative 'js/xhr.rb'

# run 'yarn add vue vue-loader vue-template-compiler'

rails_command 'webpacker:install:vue'
rails_command 'webpacker:install:erb'

f('app/javascript/lib/vue.js', 'js/lib/vue.js')

append_to_file(
  'app/javascript/packs/application.js',
  "import 'lib/vue';\n"
)
