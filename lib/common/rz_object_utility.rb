require "yaml"

module RZObjectUtility



  # returns a hash array of instance variable symbol and instance variable value for self
  # will ignore instance variables that start with '_'
  def to_hash
    hash = {}
    self.instance_variables.each {|iv| hash[iv.to_s] = self.instance_variable_get(iv) unless iv.to_s.start_with?("@_")}
    hash
  end

  # sets instance variables
  # will not include any that start with "_" (Mongo specific)
  def from_hash(hash)
    hash.each_pair {|key, value| self.instance_variable_set(key,value) unless key.to_s.start_with?("_")}
  end

  # Validates that all instance variables for the object are not nil
  def validate_instance_vars
    flag = true
    self.instance_variables.each { |iv| flag = false if (self.instance_variable_get(iv) == nil && !iv.to_s.start_with?("@_")) }
    flag
  end
end