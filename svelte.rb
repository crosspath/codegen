$main ||= self

require_relative 'functions.rb'
require_relative 'js/xhr.rb'

# run 'yarn add svelte svelte-loader'

rails_command 'webpacker:install:svelte'

f('app/javascript/lib/svelte.js', 'js/lib/svelte.js')

append_to_file('app/javascript/packs/application.js') do
  <<-LINE
import 'lib/svelte';
import 'lib/xhr';
  LINE
end
