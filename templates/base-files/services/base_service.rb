# В сервисных обектах обычно находится та часть программной логики, которая использует
# несколько объектов БД, отправляет или запрашивает данные из веб-сервисов.
#
# Если необходимо добавить какой-то код, выполняемый во время создания, изменения или удаления
# какого-либо объекта БД, то для этого удобнее поместить такой код в форму (см. BaseForm).
#
# Пример сервисного обекта:
#
#     module RequestService
#       module FreezeDeals
#         extend BaseService
#
#         def self.call(requests)
#           now = Time.now
#           ok  = requests.all? { |request| request.update(finished_at: now) }
#           result(ok, collection(requests))
#         end
#       end
#     end

module BaseService
  Result = Struct.new(:success, :object, :messages) do
    def errors
      res     = {}
      details = object.respond_to?(:errors) && object.errors

      res[:messages] = messages if messages.present?
      res[:details]  = details.to_hash if details.present?

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

  Collection = Struct.new(:items) do
    def errors
      helper = CollectionErrorsHelper.new({})

      items.flat_map { |item| helper.messages_for(item) }.to_h
    end
  end

  CollectionErrorsHelper = Struct.new(:counter) do
    def messages_for(item)
      key = item.class.name

      use_key(key) { item.respond_to?(:errors) ? generate_messages(item, key) : [] }
    end

    private

    def use_key(key)
      counter[key] ||= [key.underscore, 0]
      result = yield
      counter[key][1] += 1
      result
    end

    def generate_messages(item, key)
      name, count = counter[key]

      item.errors.map do |*error|
        # Rails 6.0 requires block with 2 arguments: attribute name and message.
        # Rails 6.1 requires block with 1 argument: instance of ActiveModel::Error.
        attribute, message = error.size == 1 ? [error[0].attribute, error[0].message] : error

        ["#{name}[#{count}].#{attribute}", message]
      end
    end
  end

  def collection(items)
    Collection.new(items)
  end

  def result(success, object = nil, messages = [])
    Result.new(success, object, messages)
  end

  def success(object = nil, messages = [])
    Result.new(true, object, messages)
  end

  def failure(object = nil, messages = [])
    Result.new(false, object, messages)
  end
end
