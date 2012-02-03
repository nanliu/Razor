# Razor config - this is imported via a YAML file define by install

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "utility"

module Razor
class Configuration
  # Mixin our ObjectUtilities
  include(Razor::Utility)

  attr_accessor :persist_mode
  attr_accessor :persist_host
  attr_accessor :persist_port
  attr_accessor :persist_timeout
  
  attr_accessor :admin_port
  attr_accessor :api_port
  attr_accessor :log_path
  
  def initialize
    use_defaults
  end
  
  
  def use_defaults
    @persist_mode = :mongo
    @persist_host = "127.0.0.1"
    @persist_port = 27017
    @persist_timeout = 10
    
    @admin_port = 8017
    @api_port = 8026
    @logpath = "#{ENV['RAZOR_HOME']}/log/"
  end


end
end