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

  # Set default values
  def initialize
    @uuid = create_uuid
    @version = 0
  end

  private
  # Return a new UUID string
  def create_uuid
    UUID.generate(format = :compact)
  end
end