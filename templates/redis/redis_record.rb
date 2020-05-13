class RedisRecord
  include ActiveModel::Model
  include ActiveModel::Dirty

  attr_accessor :name, :value

  define_attribute_methods :name, :value

  class << self
    def redis
      Redis.new
    end

    def load(name)
      self.new(name: name, value: redis.get(name))
    end
  end

  [:name, :value].each do |attr|
    define_method("#{attr}=") do |v|
      unless v == instance_variable_get("@#{attr}")
        public_send("#{attr}_will_change!")
      end
      instance_variable_set("@#{attr}", v)
    end
  end

  def initialize(*args, **kwargs)
    super(*args, **kwargs)
    clear_changes_information
  end

  def inspect
    "\#<#{self.class.name} name=#{name.inspect} value=#{value.inspect}>"
  end

  def save
    redis = self.class.redis
    redis.del(name_was) if name_changed?
    redis.set(name, value)

    changes_applied
  end

  def reload!
    self.name = name_was
    self.value = self.class.redis.get(name)

    clear_changes_information
  end

  def rollback!
    restore_attributes
  end
end
