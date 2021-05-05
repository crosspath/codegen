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
#       permit :name, :content, :published, category_ids: []
#
#       # Список разрешённых атрибутов только для `create`
#       # и только для `update`.
#       permit_for create: [{attachments: []}],
#           update: [:created_at]
#
#       # Можно убрать метод для удаления объектов.
#       undefine_form_method :destroy
#       # Можно указывать несколько методов через запятую:
#       # undefine_form_method :create, :update, :destroy
#
#       # Можно переопределить стандартные методы (create, update, destroy) и добавить свои.
#       # Например, отправка писем, удаление связанных объектов в транзакции, обновление счётчиков.
#
#       def self.create(params, author)
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
#     # => NoMethodError
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
      res = self[:errors] || []
      res += object.errors.messages.values.flatten if object.respond_to?(:errors)
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

  def create(params)
    object = new_model_object(params)
    yield(object) if block_given?
    result(object.save, object)
  end

  def update(object, params)
    object.attributes = attributes(params, :update)
    yield(object) if block_given?
    result(object.save, object)
  end

  def destroy(object)
    result(object.destroy, object)
  end

  # DSL, module-scoped methods

  def permit(*attributes_list)
    @_permit = attributes_list
  end

  def permit_for(options = {})
    @_permit_for ||= {}
    @_permit_for.merge!(options.symbolize_keys)
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

  def new_model_object(params)
    model_class.new(attributes(params, :create))
  end

  def model_class
    @_model_name ||= self.name.sub(/Form$/, '')
    @_model_name.constantize
  end

  def attributes(params, key = nil)
    attrs_list = @_permit || []
    attrs_list += key && @_permit_for && @_permit_for[key.to_sym] || []
    unless params.respond_to?(:permit)
      params = ActionController::Parameters.new(params)
    end
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
