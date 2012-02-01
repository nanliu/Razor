require "yaml"

module RZObjectUtility

  # returns a hash array of instance variable symbol and instance variable value for self
  def to_hash
    hash = {}
    self.instance_variables.each {|inst| hash[inst.to_s] = self.instance_variable_get(inst)}
    hash
  end

  # sets instance variables
  def from_hash(hash)
    hash.each_pair {|key, value| self.instance_variable_set(key,value)}
  end

  # Validates that all instance variables for the object are not nil
  def validate_instance_vars
    flag = true
    self.instance_variables.each { |iv| flag = false if self.instance_variable_get(iv) == nil }
    flag
  end
end