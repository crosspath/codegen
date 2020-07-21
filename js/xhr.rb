$main.gem 'blueprinter'
$main.gem 'railbus'

$main.run 'yarn add axios'

after_bundle_install do
  $main.rails_command 'webpacker:install:erb'

  $main.inject_into_file(
    'config/webpacker.yml',
    "    - .js.erb\n",
    after: "- .js\n"
  )
end

d('app/javascript/lib', 'js/lib')

$main.append_to_file('app/javascript/packs/application.js') do
  "import 'lib/xhr';\n"
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
      @_serializer_name.constantize
    end

    def serialized(serializer: serializer_class, **options)
      serializer.render_as_hash(self.all, **options)
    end
  end

  def serialized(serializer: self.class.serializer_class, **options)
    serializer.render_as_hash(self, **options)
  end
  END
end
