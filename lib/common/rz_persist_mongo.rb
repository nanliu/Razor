# This is the superclass for all database object types
# there are database object types for each possible database that can back Razor
# common functions are created here to handle accessors and key/values
# Child object types override when needed for specific type
# All keys are assumed to be simple string and all values are assumed to be YAML string

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_persist_object"
require "mongo"

class RZPersistMongo < RZPersistObject

  def teardown
    # teardown is a signal from the controller to kill any instance connection if it exists
    @connection.active? && disconnect
  end

  def connect(hostname, port)
    @connection = Mongo::Connection.new(hostname, port)
    @razor_database = @connection.db("razor")
    @connection.active?
  end

  def disconnect
    @connection.close
    @connection.active?
  end

  def is_db_selected?
    if (@razor_database != nil and @connection.active?)
      true
    else
      false
    end
  end



  def model_get_all
    model_hash_array = []
    model_collection.find().each {|x| model_hash_array << x}
    model_hash_array
  end

  def model_update(id, model_hash)
    model_collection.update({"_id" => id}, model_hash)
  end

  def model_insert(model_hash)
    model_collection.insert(model_hash)
  end


  private

  def model_collection
    @razor_database.collection("model")
  end


end