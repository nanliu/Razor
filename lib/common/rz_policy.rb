# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_object"

# Razor Policy class
# Used to apply RZModel to RZNode
class RZPolicy < RZObject
  #noinspection RubyResolve
  attr_accessor :name
  attr_accessor :model
  attr_accessor :policy_type

  # @param hash [Hash]
  def initialize(hash)
    super()
    @_collection = :policy
    from_hash(hash)
  end
end