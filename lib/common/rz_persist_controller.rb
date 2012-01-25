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

  # get specific model with 'gui'
  def with_guid(guid)

  end

  # get all models in an array
  def model_get_all
    model_array = []
    @persist_obj.model_get_all.each do
      |model_hash|
      model = RZModel.new(model_hash)
      model_array << model
    end
    model_array
  end

  # get all models matching attributes in a hash returns array
  def matching(hash)

  end

  # insert/update model
  def model_update(model)
    # Get our existing models
    model_array = model_get_all

    # Loop through existing and see if we find a match
    model_array.each do
      |existing_model|

      # If the GUID matches then we update this record and return
      if model.guid == existing_model.guid
          return @persist_obj.model_update(existing_model["_id"], model.to_hash)
      end
    end

    # We didn't find a matching model so we insert this instead
    @persist_obj.model_insert(model.to_hash)
  end

  # remove model from table/collection
  def delete(guid)

  end


end