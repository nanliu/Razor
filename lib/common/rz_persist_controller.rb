# This class receives key/values and persists into chosen database
# Database is bound on init
# You cannot change database type after init

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_configuration"
require "rz_persist_mongo"
require "rz_model"

class RZPersistController
   attr_accessor :database
   attr_accessor :config
   # @param @config [RZConfiguration]


   def initialize(config)
      # copy config into instance
      @config = config

      # init correct database object
      if (config.persist_mode = :mongo)
        @database = RZPersistMongo.new
        check_connection
      end

   end

   def teardown
     @database.teardown
   end

  # Returns true|false whether DB/Connection is open
  # Use this when you want to check but not reconnect
  def is_connected?
    @database.is_db_selected?
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
    @database.connect(@config.persist_host, @config.persist_port)
  end



  # model operations

  # get all models in an array
  def object_hash_get_all(collection)
    @database.object_doc_get_all(collection)
  end

  # insert/update model
  def object_hash_update(object_doc, collection)
    @database.object_doc_update(object_doc, collection)
  end

  # remove model from table/collection
  def object_hash_remove(object_doc, collection)
    @database.object_doc_remove(object_doc, collection)
  end


end