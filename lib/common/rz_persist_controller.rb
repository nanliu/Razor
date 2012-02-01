# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_configuration"
require "rz_persist_database_mongo"
require "rz_model"

# Persistence Controller for Razor
class RZPersistController
  attr_accessor :database
  attr_accessor :config

  # Initializes the controller and configures the correct '@database' object based on the 'persist_mode' specified in the config
  # @param @config [RZConfiguration]
  def initialize(config)
    # copy config into instance
    @config = config

    # init correct database object
    if (config.persist_mode = :mongo)
      @database = RZPersistDatabaseMongo.new
      check_connection
    end
  end

  # This is where all connection teardown is started. Calls the '@database.teardown'
  def teardown
    @database.teardown
  end

  # Returns true|false whether DB/Connection is open
  # Use this when you want to check but not reconnect
  # @return [true, false]
  def is_connected?
    @database.is_db_selected?
  end

  # Checks and reopens closed DB/Connection
  # Use this to check connection after trying to make sure it is open
  # @return [true, false]
  def check_connection
    is_connected? || connect_database
    # return connection status
    is_connected?
  end

  # Connect to database using RZPersistDatabaseObject loaded
  def connect_database
    @database.connect(@config.persist_host, @config.persist_port, @config.persist_timeout)
  end




  # Get all object documents from database collection: 'collection'
  # @param collection [Symbol] - name of the collection
  # @return [Array] - Array containing the
  def object_hash_get_all(collection)
    @database.object_doc_get_all(collection)
  end

  # Add/update object document to the collection: 'collection'
  # @param object_doc [Hash]
  # @param collection [Symbol]
  # @return [Array]
  def object_hash_update(object_doc, collection)
    @database.object_doc_update(object_doc, collection)
  end

  # Remove object document with UUID from collection: 'collection' completely
  # @param object_doc [Hash]
  # @param collection [Symbol]
  # @return [true, false]
  def object_hash_remove(object_doc, collection)
    @database.object_doc_remove(object_doc, collection) || false
  end


end