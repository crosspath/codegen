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
  Result = Struct.new(:success, :object, :errors) do
    def errors
      res = {}
      res[:messages] = self[:errors] if self[:errors].present?
      res[:details]  = object.errors.to_hash if object.respond_to?(:errors) && !object.errors.empty?
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

  # rubocop:disable Metrics/AbcSize
  Collection = Struct.new(:items) do
    def errors
      names_map = {}
      count_map = {}

      items.flat_map do |item|
        next unless item.respond_to?(:errors)

        name = item.class.name
        names_map[name] ||= name.underscore
        count_map[name] ||= 0

        index = count_map[name]
        count_map[name] += 1

        item.errors.map do |error|
          ["#{names_map[name]}[#{index}].#{error.attribute}", error.message]
        end
      end.to_h
    end
  end
  # rubocop:enable Metrics/AbcSize

  def collection(items)
    Collection.new(items)
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
