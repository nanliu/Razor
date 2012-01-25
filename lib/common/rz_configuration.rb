# Razor config - this is imported via a YAML file define by install

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_PATH']}lib/common"

class RZConfiguration
  attr_accessor :persist_mode
  attr_accessor :persist_host
  attr_accessor :persist_port
  
  attr_accessor :admin_port
  
  attr_accessor :api_port
  
  def initialize
    use_defaults
  end
  
  
  def use_defaults
    @persist_mode = :mongo
    @persist_host = "127.0.0.1"
    @persist_port = "27017"
    
    @admin_port = "8017"
    @api_port = "8026"
  end
  
end