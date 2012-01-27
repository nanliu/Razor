
# Custom Matches for RSpec testing
module RZRSpecMatchers
  class KeysWithValuesCountEquals
    # @param key_value_hash [Hash]
    # @param count [Numeric]
    def initialize(key_value_hash, count)
      @key_value_hash = key_value_hash
      @count = count
    end

    # @param hash_array [Array]
    def matches?(hash_array)
      @hash_array = hash_array
      @actual_count = 0

      @hash_array.each do
      |hash|
        match_count = 0
        @key_value_hash.each_pair { |key, value| (hash[key] == value) && match_count += 1 }
        (match_count == @key_value_hash.count) && @actual_count += 1
      end

      (@actual_count == @count)
    end

    def failure_message
      "Hash actual count (#{@actual_count}) with key/values: (#{@key_value_hash}) \n DOES NOT equal: (#{@count}) in array:\n #{@hash_array.inspect}"
    end
    def negative_failure_message
      "Hash actual count (#{@actual_count}) with key/values: (#{@key_value_hash}) \n DOES equal: (#{@count}) in array:\n #{@hash_array.inspect}"
    end

  end
  # @param key_value_hash [Hash]
  # @param count [Numeric]
  def keys_with_values_count_equals(key_value_hash, count)
    KeysWithValuesCountEquals.new(key_value_hash, count)
  end

end