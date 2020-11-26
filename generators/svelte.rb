Generator.add_actions do |answers|
  next unless answers[:svelte]

  require_relative '../js/xhr.rb'

  $main.rails_command 'webpacker:install:svelte'

  d('app/javascript/lib', 'svelte/lib')

  $main.append_to_file('app/javascript/packs/application.js') do
    "import 'lib/svelte';\n"
  end
end
