# Без валидаций в формах, поскольку валидации выполняются на уровне моделей.
# Поддерживаемые действия: `create`, `update`, `destroy`.
# Можно добавлять свои действия как методы модуля.
#
# Пример формы:
#
#     module ArticleForm
#       extend BaseForm
#
#       # Список разрешённых атрибутов для всех действий,
#       # используется в действиях `create` и `update`.
#       permit attributes: [:name, :content, :published, category_ids: []]
#
#       # Список разрешённых атрибутов только для `create`
#       # и только для `update`.
#       permit attributes: [{attachments: []}], on: :create
#       permit attributes: [:created_at], on: :update
#
#       # Можно убрать метод для удаления объектов.
#       undefine_form_method :destroy
#       # Можно указывать несколько методов через запятую:
#       # undefine_form_method :create, :update, :destroy
#
#       # Можно переопределить стандартные методы (create, update, destroy) и добавить свои.
#       # Например, отправка писем, удаление связанных объектов в транзакции, обновление счётчиков.
#
#       def self.create(params, author:)
#         super(params) do |object|
#           object.version = 0
#           object.author  = author
#         end
#       end
#
#       def self.update(object, params)
#         super(object, params) do |_object|
#           object.version += 1
#         end
#       end
#
#       # def self.destroy(object)
#       #   super(object).on_success do |_result|
#       #     UserMailer.object_deleted(object)
#       #   end
#       # end
#     end
#
# Применение в контроллере:
#
#     p ArticleForm.create(params.require(:article))
#     # => #<struct BaseForm::Result success=..., object=..., errors=[...]>
#
#     p ArticleForm.update(Article.first, params.require(:article))
#     # => #<struct BaseForm::Result success=..., object=..., errors=[...]>
#
#     p ArticleForm.destroy(Article.first)
#     # => NoMethodError, потому что этот метод убран через undefine_form_method
#
# Метод `for_collection` можно использовать для обработки множества объектов.
# Пример метода формы:
#
#     def self.create(names)
#       for_collection do |_errors, objects|
#         names.each do |name|
#           object = model_class.find_of_create_by(name: name)
#           objects << object unless object.valid?
#         end
#       end
#     end

module BaseForm
  Result = Struct.new(:success, :object, :errors)
  Result.class_eval do
    def errors
      res = {}
      res[:messages] = self[:errors] if self[:errors].present?
      res[:details] = object.errors.to_hash if object.respond_to?(:errors)
      res
    end

    def on_success
      yield(self) if success
      self
    end

    def on_failure
      yield(self) unless success
      self
    end
  end

  # Form actions

  def create(params, **options)
    object = model_class.new(attributes(params, :create, **options))
    yield(object) if block_given?
    result(object.save, object)
  end

  def update(object, params, **options)
    object.attributes = attributes(params, :update, **options)
    yield(object) if block_given?
    result(object.save, object)
  end

  def destroy(object, **_options)
    result(object.destroy, object)
  end

  # DSL, module-scoped methods

  def permit(attributes: [], on: nil, check: nil)
    @_permit ||= []
    @_permit << {attributes: attributes, on: on&.to_sym, check: check}
  end

  def model_name(class_name)
    @_model_name = class_name
  end

  def undefine_form_method(*actions)
    singleton_class.class_eval do
      undef_method(*actions)
    end
  end
  alias :undefine_form_methods :undefine_form_method

  private

  # Helper methods for form actions

  def model_class
    @_model_name ||= self.name.sub(/Form$/, '')
    @_model_name.constantize
  end

  def attributes(params, key = nil, **options)
    key = key&.to_sym

    selected = (@_permit || []).select do |hash|
      (hash[:on].nil? || hash[:on] == key) && (hash[:check].nil? || hash[:check].call(options))
    end

    attrs_list = selected.flat_map { |hash| hash[:attributes] }

    params = ActionController::Parameters.new(params) unless params.respond_to?(:permit)
    params.permit(attrs_list)
  rescue NoMethodError
    raise ArgumentError, "Unexpected value: #{params.inspect}"
  end

  def for_collection
    errors  = []
    objects = []

    yield errors, objects

    objects.each do |obj|
      errors.concat(obj.errors.messages.values.flatten) if obj.respond_to?(:errors)
    end

    result(errors.empty?, objects, errors.uniq)
  end

  def result(success, object = nil, errors = [])
    Result.new(success, object, errors)
  end

  def success(object = nil, errors = [])
    Result.new(true, object, errors)
  end

  def failure(object = nil, errors = [])
    Result.new(false, object, errors)
  end
end
