# This class receives key/values and persists into chosen database
# Database is bound on init
# You cannot change database type after init

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_configuration"
require "rz_persist_mongo"
require "rz_model"

class RZPersistController
   attr_accessor :persist_obj
   attr_accessor :config
   # @param @config [RZConfiguration]


   def initialize(config)
      # copy config into instance
      @config = config

      # init correct database object
      if (config.persist_mode = :mongo)
        @persist_obj = RZPersistMongo.new
        check_connection
      end

   end

   def teardown
     @persist_obj.teardown
   end

  # Returns true|false whether DB/Connection is open
  # Use this when you want to check but not reconnect
  def is_connected?
    @persist_obj.is_db_selected?
  end

  # Checks and reopens closed DB/Connection
  # Use this to check connection after trying to make sure it is open
  def check_connection
    is_connected? || connect_database
    # return connection status
    is_connected?
  end

  # Connect to database using RZPersistObject loaded
  def connect_database
    @persist_obj.connect(@config.persist_host, @config.persist_port)
  end



  # model operations
  def model


    # get specific model with 'gui'
    def with_guid(guid)

    end

    # get all models in an array
    def all
      @persist_obj.model.get
    end

    # get all models matching attributes in a hash returns array
    def matching(hash)

    end

    # save/update model
    def save(model)

    end

    # remove model from table/collection
    def delete(guid)

    end
  end

end