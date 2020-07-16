$main.gem 'blueprinter'
$main.gem 'js-routes'

$main.run 'yarn add axios'

$main.initializer 'js_routes.rb', <<-LINE
JsRoutes.setup do |config|
  config.exclude = [/^sidekiq/, /^rails/, /^update_rails/]
  config.include = [//]
  config.compact = true
end
LINE

after_bundle_install do
  $main.rails_command 'webpacker:install:erb'
end

f('app/javascript/lib/xhr.js', 'js/xhr.js')
f('app/javascript/lib/dom.js', 'js/dom.js')

$main.inject_into_file(
  'app/models/application_record.rb',
  after: 'self.abstract_class = true'
) do
  <<-END

  class << self
    def serializer_name(class_name)
      @_serializer_name = class_name
    end

    def serializer_class
      @_serializer_name ||= "#{self.name}Serializer".freeze
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
