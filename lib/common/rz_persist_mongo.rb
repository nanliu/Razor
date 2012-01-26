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

    # iterate over each hash returned, sort descending by _timestamp
    model_collection.find().sort("@name",1).sort("_timestamp",-1).each do
      |x|

      flag = false
      model_hash_array.each do
      |y|
        if y[:@guid] == x[:@guid]
          flag =  true
        end
      end

      if !flag
        # remove the Mongo "_id" key as it won't match an instance variable
        x.delete("_id")
        # remove timestamp also
        x.delete("_timestamp")

        # add hash to hash array
        model_hash_array << x
      end
    end

    # return hash array
    model_hash_array
  end

  def model_update(model_doc)

    # Add a timestamp key
    # We use this to always pull newest
    model_doc["_timestamp"] = Time.now.to_i
    model_collection.insert(model_doc)
    cleanup_old_timestamps
  end

  def model_remove(model_doc)
    model_collection.remove({"@guid" => model_doc["@guid"]})
  end


  private

  def cleanup_old_timestamps
    model_hash_array = []
    model_collection.find().sort("@name",1).sort("_timestamp",-1).each do
      |model_record|

      flag = false
      model_hash_array.each do
      |y|
        if y[:@guid] == model_record[:@guid]
          flag =  true
        end
      end

      if flag
          model_collection.remove({"_id" => model_record["_id"]})
        else
          model_hash_array << model_record
        end
      end
  end

  def model_collection
    @razor_database.collection("model")
  end

end