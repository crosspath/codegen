# Без валидаций в формах, поскольку валидации выполняются на уровне моделей.
# Поддерживаемые действия: `create`, `update`, `destroy`.
# Можно добавлять свои действия как методы класса формы.
#
# Пример формы:
#     class ArticleForm < BaseForm
#       # Название класса модели определяется как строка до слова "Form"
#       # в названии класса формы. Если нужно использовать другую модель,
#       # тогда нужен параметр `model_name`.
#       model_name :Article
#
#       # Список разрешённых атрибутов для всех действий,
#       # используется в действиях `create` и `update`.
#       permit :name, :content, :published, category_ids: []
#
#       # Список разрешённых атрибутов только для `create`
#       # и только для `update`.
#       permit_for create: [{attachments: []}],
#           update: [:created_at]
#     end
#
# Применение в контроллере:
#     form = ArticleForm.create(params[:article])
#     if form.success
#       redirect_to article_path(form.object)
#     else
#       @article = form.object
#       flash.now[:alert] = form.errors
#       render :show
#     end
#
# Можно сделать недоступными методы `create`, `update` или `destroy`,
# если добавить такую строку в класс формы:
#     class << self; private :create; end
#
# Можно переопределить методы `create`, `update` и `destroy`, если нужно
# добавить в них аргументы или дополнительные действия, например, отправку
# писем.
# Например, в методе `destroy` можно удалить связанные объекты в транзакции,
# обновить счётчики и отправить электронное письмо.
#
# Метод `collect_errors` можно использовать для обработки множества объектов.
# Пример метода класса формы:
#
#     def create(names)
#       collect_errors do |errors, objects|
#         names.each do |name|
#           object = model_class.find_of_create_by(name: name)
#           objects << object unless object.valid?
#         end
#       end
#     end
#
class BaseForm
  class << self
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

    def create(params)
      object = new_model_object(params)

      self.new(object.save, object)
    end

    def update(object, params)
      object.attributes = attributes(params, :update)

      self.new(object.save, object)
    end

    def destroy(object)
      self.new(object.destroy, object)
    end

    private

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

    def collect_errors
      errors  = []
      objects = []

      yield errors, objects

      objects.each do |obj|
        errors.concat(obj.errors.messages.values.flatten)
      end

      empty_object = model_class.new
      empty_object.errors[:base].concat(errors.uniq)
      self.new(errors.empty?, empty_object)
    end
  end

  attr_reader :success, :object

  def initialize(success, object)
    @success = success
    @object  = object
  end

  def errors
    @object ? @object.errors.messages.values.flatten : []
  end
end
