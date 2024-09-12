# frozen_string_literal: true

# Base class for "registering" features & subfeatures.
# It helps to dynamically retrieve registered items in specific order.
# @abstract
class Registry
  def initialize
    @all = []
  end

  # @param item [#hash_key] Struct-like object
  # @return [void]
  def add(item, before = nil)
    if before
      index = @all.find_index { |h| h[:name] == before }
      return @all.insert(index, item) if index
    end

    @all << item
  end

  # @return [Hash<String, Object>]
  def all
    @all.to_h { |item| [item.hash_key, item] }
  end
end
