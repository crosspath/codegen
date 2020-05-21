class BaseQuery
  attr_reader :relation

  class << self
    # Можно в классах `*Query` переопределить название класса модели
    def model_name(class_name)
      @_model_name = class_name
    end

    def model_class
      @_model_name ||= self.name.sub(/Query$/, '')
      @_model_name.constantize
    end
  end

  # @param rel: class | instance of #{class}::ActiveRecord_Relation
  def initialize(rel = nil)
    @relation = rel || self.class.model_class
  end

  %w[blank? present? empty? all].each do |mth|
    define_method(mth) do
      @relation.public_send(mth)
    end
  end

  def presence
    method_missing(:presence)
  end

  # Поддержка цепочек вызовов функций из ActiveRecord
  def method_missing(mth, *args, &block)
    result = @relation.public_send(mth, *args, &block)

    if result.is_a?(ActiveRecord::Relation)
      self.class.new(result)
    else
      result
    end
  end
end
