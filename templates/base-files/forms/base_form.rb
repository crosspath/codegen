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

module BaseForm
  include BaseService

  # Form actions

  def create(params, **options)
    object = model_class.new(attributes(params, :create, **options))
    yield(object) if block_given?
    result(object.save, object)
  end

  def update(object, params, **options)
    object.attributes = attributes(params, :update, object: object, **options)
    yield(object) if block_given?
    result(object.save, object)
  end

  def destroy(object, **_options)
    result(object.destroy, object)
  end

  # DSL, module-scoped methods

  def permit(attributes: [], on: nil, check: nil)
    @_permit ||= []
    @_permit << { attributes: attributes, on: on&.to_sym, check: check }
  end

  def model_name(class_name)
    @_model_name = class_name
  end

  def undefine_form_method(*actions)
    singleton_class.class_eval do
      undef_method(*actions)
    end
  end
  alias undefine_form_methods undefine_form_method

  private

  # Helper methods for form actions

  def model_class
    @_model_name ||= name.sub(/Form$/, '')
    @_model_name.constantize
  end

  def attributes(params, key = nil, **options)
    params = ActionController::Parameters.new(params) unless params.respond_to?(:permit)
    params.permit(attributes_list(key, **options))
  rescue NoMethodError
    raise ArgumentError, "Unexpected value: #{params.inspect}"
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Style/ParallelAssignment
  def attributes_list(key = nil, **options)
    key = key&.to_sym

    selected = (@_permit || []).select do |hash|
      (hash[:on].nil? || hash[:on] == key) && (hash[:check].nil? || hash[:check].call(options))
    end

    attrs_list  = selected.flat_map { |hash| hash[:attributes] }
    array, hash = merge_attributes_list(attrs_list)

    replace_empty_hash_in_array_to_hash(array + [hash])
  end

  def merge_attributes_list(attrs_list)
    array, hash = [], {}

    attrs_list.each do |e|
      case e
      when Array
        new_array, new_hash = combine_attributes(e)
        array += new_array
        hash.merge!(new_hash)
      when Hash
        e.each do |k, v|
          # Для операции вида "разрешить все ключи" используется запись вида `атрибут: {}`, но если
          # использовать `атрибут: [{}]`, то ни один ключ не попадёт в результат. Эта ситуация
          # исправляется дальше в `replace_empty_hash_in_array_to_hash`.
          if v == {}
            hash[k] ||= [{}]
          else
            new_array, new_hash = merge_attributes_list(Array.wrap(hash[k]) + Array.wrap(v))
            hash[k] = new_array + (new_hash.empty? ? [] : [new_hash])
          end
        end
      else
        array << e
      end
    end

    [array, hash]
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Style/ParallelAssignment

  def replace_empty_hash_in_array_to_hash(list)
    list.map do |e|
      if e.is_a?(Hash)
        e.transform_values { |v| v == [{}] ? {} : replace_empty_hash_in_array_to_hash(v) }
      else
        e
      end
    end
  end
end
