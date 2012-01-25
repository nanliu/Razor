# This class receives key/values and persists into chosen database
# Database is bound on init
# You cannot change database type after init

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_configuration"
require "rz_persist_mongo"

class RzPersistController
       attr_accessor :persist_obj
       # @param config [RZConfiguration]
       def initialize(config)
          # init correct database object
          if (config.persist_mode = :mongo)
            @persist_obj = RzPersistMongo.new
          end
       end
end