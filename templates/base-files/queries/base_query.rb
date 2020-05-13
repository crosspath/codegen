class BaseQuery
  attr_reader :relation

  # @param rel: class | instance of #{class}::ActiveRecord_Relation
  def initialize(rel)
    @relation = rel
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
