# Parent class for all Razor Models
# This class will have child classes per deploy model type

class RZModel
  # most of this is mock right now

  attr_accessor :name
  attr_accessor :guid
  attr_accessor :model_type
  attr_accessor :values_hash


  def initialize(model_hash)
    from_hash(model_hash)
  end

  def to_hash
    { :name => @name, :guid => @guid, :model_type => @model_type, :values_hash => @values_hash }
  end

  def from_hash(model_hash)
    @name = model_hash[:name]
    @guid = model_hash[:guid]
    @model_type = model_hash[:model_type]
    @values_hash = model_hash[:values_hash]
  end

end