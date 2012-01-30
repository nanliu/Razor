# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_object"

# This class is the interface to all querying and saving of data
# This class uses the RzPersistController class to persist changes to the chosen database
class RZData < RZObject
  def initialize

  end



end