# Parent class for all Razor Models
# This class will have child classes per deploy model type

class RZModel
  # most of this is mock right now

  attr_accessor :name
  attr_accessor :guid
  attr_accessor :model_type
  attr_accessor :values_hash


  def initialize(name, guid, model_type, values_hash)
    @name = name
    @guid = guid
    @model_type = model_type
    @values_hash = values_hash
  end

  def to_hash
    { :name => @name, :guid => @guid, :model_type => @model_type, :values_hash => @values_hash }
  end

end