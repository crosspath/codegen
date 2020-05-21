# Без валидаций в формах, поскольку валидации выполняются на уровне моделей.
# Поддерживаемые действия: `create`, `update`, `destroy`.
#
# Пример формы:
#     class ArticleForm < BaseForm
#       # Название класса модели определяется как строка до слова "Form"
#       # в названии класса формы. Если нужно использовать другую модель,
#       # тогда нужен параметр `model_name`.
#       model_name :Article
#
#       # Список разрешённых атрибутов для `create` и `update`.
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
class BaseForm
  class << self
    def permit(*attributes)
      @_permit = attributes
    end

    def permit_for(create: [], update: [])
      @_permit_for_create = create
      @_permit_for_update = update
    end

    def model_name(class_name)
      @_model_name = class_name
    end

    def create(params)
      object = new_model_object(params)

      self.new(object.save, object)
    end

    def update(object, params)
      object.attributes = update_attributes(params)

      self.new(object.save, object)
    end

    def destroy(object)
      self.new(object.destroy, object)
    end

    private

    def new_model_object(params)
      model_class.new(create_attributes(params))
    end

    def model_class
      @_model_name ||= self.name.sub(/Form$/, '')
      @_model_name.constantize
    end

    def create_attributes(params)
      attrs_list = (@_permit || []) + (@_permit_for_create || [])
      safe_attributes(params, attrs_list)
    end

    def update_attributes(params)
      attrs_list = (@_permit || []) + (@_permit_for_update || [])
      safe_attributes(params, attrs_list)
    end

    def safe_attributes(params, attrs_list)
      unless params.respond_to?(:permit)
        params = ActionController::Parameters.new(params)
      end
      params.permit(attrs_list)
    rescue NoMethodError
      raise ArgumentError, "Unexpected value: #{params.inspect}"
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
