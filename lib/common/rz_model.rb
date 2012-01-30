# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_object"

class RZModel < RZObject


  attr_accessor :name
  attr_accessor :model_type
  attr_accessor :values_hash



  # @param hash [Hash]
  def initialize(hash)
    super()
    from_hash(hash)
  end
end