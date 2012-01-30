# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_object"

# Razor Policy class
# Used to apply RZModel to RZNode
class RZPolicy < RZObject
  attr_accessor :name
  attr_accessor :uuid
  attr_accessor :model
end