# Parent class for all Razor Models
# This class will have child classes per deploy model type
# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_object_utility"

class RZModel
  # most of this is mock right now
  include(RZObjectUtility)

  attr_accessor :name
  attr_accessor :uuid
  attr_accessor :model_type
  attr_accessor :values_hash


  def initialize(model_hash)
    from_hash(model_hash)
  end

end