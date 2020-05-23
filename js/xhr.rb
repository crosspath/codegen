$main.gem 'blueprinter'

$main.run 'yarn add axios axios-rest-client'

f('app/javascript/lib/api.js', 'js/api.js')
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
