def xhr_gems
  $main.gem 'blueprinter'
  $main.gem 'railbus'
end

def xhr_packages(answers)
  if answers[:axios]
    add_npm_package('axios')
  else
    add_npm_package('@crosspath/yambus-fetch')
  end
end

def xhr_after_bundle(answers)
  $main.generate('railbus:install')

  $main.rails_command 'webpacker:install:erb'

  $main.inject_into_file(
    'config/webpacker.yml',
    "    - .js.erb\n",
    after: "- .js\n"
  )

  d('app/javascript/lib', 'js/lib')
  $main.remove_file('app/javascript/lib/xhr.js') unless answers[:axios]
end

def xhr_axios
  $main.append_to_file('app/javascript/packs/application.js') do
    "import '../lib/xhr';\n"
  end
end

def xhr_application_record
  $main.inject_into_file(
    'app/models/application_record.rb',
    after: "primary_abstract_class\n"
  ) do
    <<-END

  class << self
    def serializer_name(class_name)
      @_serializer_name = class_name
    end

    def serializer_class
      @_serializer_name ||= "\#{self.name}Serializer".freeze
      const_defined?(@_serializer_name) ? const_get(@_serializer_name) : nil
    end
  end

  def serializable_hash(options = {})
    serializer = options.delete(:serializer) || self.class.serializer_class
    serializer ? serializer.render_as_hash(self, options) : super(options)
  end
    END
  end
end

Generator.add_actions do |answers|
  next if !answers[:svelte] && !answers[:vue]

  xhr_gems
  xhr_packages(answers)
  xhr_axios if answers[:axios]
  xhr_application_record

  after_bundle_install do
    xhr_after_bundle(answers)
  end
end
