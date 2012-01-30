$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "uuid"
require "rz_object_utility"

# Common object for all base Razor objects
class RZObject
  # Mixin our ObjectUtilities
  include(RZObjectUtility)

  # There variables are required in all Razor objects
  attr_accessor :uuid
  attr_accessor :version


  def initialize
    @uuid = create_uuid
    @version = 0
  end

  private
  def create_uuid
    UUID.generate(format = :compact)
  end
end