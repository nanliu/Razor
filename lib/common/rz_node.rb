# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"


# Razor class representing Nodes
class RZNode
  attr_accessor :name
  attr_accessor :uuid
  attr_accessor :last_state
  attr_accessor :current_state
  attr_accessor :next_state

end