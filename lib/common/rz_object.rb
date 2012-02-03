$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "uuid"
require "rz_object_utility"

# Common object for all base Razor objects
class RZObject
  # Mixin our ObjectUtilities
  include(RZObjectUtility)

  # There variables are required in all Razor objects
  attr_accessor :uuid # All objects must have a uuid / can be overridden in child object
  attr_accessor :version # All objects must have a version that is incremented on updates
  attr_accessor :classname # Classname will contain a string representation of the end Class / used for dynamically loading back from DB
  #noinspection RubyResolve
  attr_accessor :_persist_ctrl # instance ref pointing to RZPersistController of RZData that created/fetched this object used for update/refresh
  attr_reader   :_collection # Collection/Table symbol for RZPersistController / Must be specified(overridden) in each child class

  # Set default values
  def initialize
    @uuid = create_uuid
    @version = 0
    @classname = self.class.to_s
    @_collection = :object
  end


  # Refreshes object from PersistController
  def refresh_self
    new_hash = @_persist_ctrl.object_hash_get_by_uuid(self.to_hash, @_collection)
    self.from_hash(new_hash) unless new_hash == nil
  end

  # Updates object through PersistController
  def update_self
    @_persist_ctrl.object_hash_update(self.to_hash, @_collection)
    refresh_self
  end

  private

  # Return a new UUID string
  def create_uuid
    UUID.generate(format = :compact)
  end
end