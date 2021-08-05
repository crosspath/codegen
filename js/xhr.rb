$main.gem 'blueprinter'
$main.gem 'railbus'

add_npm_package('axios')

after_bundle_install do
  $main.generate('railbus:install')

  $main.rails_command 'webpacker:install:erb'

  $main.inject_into_file(
    'config/webpacker.yml',
    "    - .js.erb\n",
    after: "- .js\n"
  )

  d('app/javascript/lib', 'js/lib')
end

$main.append_to_file('app/javascript/packs/application.js') do
  "import '../lib/xhr';\n"
end

$main.inject_into_file(
  'app/models/application_record.rb',
  after: "self.abstract_class = true\n"
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
