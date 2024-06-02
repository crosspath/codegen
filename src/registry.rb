# frozen_string_literal: true

# @abstract
class Registry
  def initialize
    @all = []
  end

  # @param item [#hash_key] Struct-like object
  def add(item, before = nil)
    if before
      index = @all.find_index { |h| h[:name] == before }
      return @all.insert(index, item) if index
    end

    @all << item
  end

  def all
    @all.to_h { |item| [item.hash_key, item] }
  end
end
