# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "object"

module Razor
class Model < Razor::Object
  attr_accessor :name
  attr_accessor :model_type
  attr_accessor :values_hash


  # @param hash [Hash]
  def initialize(hash)
    @name = nil
    @model_type = nil
    @values_hash = nil
    super()
    @_collection = :model
    from_hash(hash)
  end
end
  end