# This is the superclass for all database object types
# there are database object types for each possible database that can back Razor
# common functions are created here to handle accessors and key/values
# Child object types override when needed for specific type
# All keys are assumed to be simple string and all values are assumed to be YAML string
require_relative "rz_persist_object"

class RzPersistMongo < RzPersistObject
  # To change this template use File | Settings | File Templates.
end