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



  def object_doc_get_all(collection_name)

    object_doc_array = []

    # iterate over each hash returned, sort descending by _timestamp
    collection_by_name(collection_name).find().sort("_timestamp",-1).each do
      |object_doc|

      flag = false
      object_doc_array.each do
      |existing_object_doc|
        if existing_object_doc[:@uuid] == object_doc[:@uuid]
          flag =  true
        end
      end

      if !flag
        # remove the doc "_id" key as it won't match an instance variable
        object_doc.delete("_id")
        # remove timestamp also
        object_doc.delete("_timestamp")

        # add hash to hash array
        object_doc_array << object_doc
      end
    end

    # return hash array
    object_doc_array
  end

  def object_doc_update(object_doc, collection_name)

    # Add a timestamp key
    # We use this to always pull newest
    object_doc["_timestamp"] = Time.now.to_i
    collection_by_name(collection_name).insert(object_doc)
    cleanup_old_timestamps(collection_name)
  end

  def object_doc_remove(object_doc, collection_name)
    collection_by_name(collection_name).remove({"@guid" => object_doc["@guid"]})
  end


  private

  def cleanup_old_timestamps(collection_name)
    newest_object_doc_array = []
    collection_by_name(collection_name).find().sort("_timestamp",-1).each do
      |object_doc|

      flag = false
      newest_object_doc_array.each do
      |newest_object_doc|
        if newest_object_doc[:@guid] == object_doc[:@guid]
          flag =  true
        end
      end

      if flag
          collection_by_name(collection_name).remove({"_id" => object_doc["_id"]})
        else
          newest_object_doc_array << object_doc
        end
      end
  end

  def collection_by_name(collection_name)
    @razor_database.collection(collection_name.to_s)
  end

end