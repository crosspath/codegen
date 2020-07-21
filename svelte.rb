$main ||= self

require_relative 'functions.rb'
require_relative 'js/xhr.rb'

rails_command 'webpacker:install:svelte'

d('app/javascript/lib', 'svelte/lib')

append_to_file('app/javascript/packs/application.js') do
  "import 'lib/svelte';\n"
end
