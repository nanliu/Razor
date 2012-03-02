# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "yaml"

# ProjectRazor::Utility namespace
# @author Nicholas Weaver
module ProjectRazor
  module Utility

    # Returns a hash array of instance variable symbol and instance variable value for self
    # will ignore instance variables that start with '_'
    def to_hash
      hash = {}
      self.instance_variables.each do |iv|
        if !iv.to_s.start_with?("@_") && self.instance_variable_get(iv).class != Logger
          hash[iv.to_s] = self.instance_variable_get(iv)
        end
      end
      hash
    end

    # Sets instance variables
    # will not include any that start with "_" (Mongo specific)
    # @param [Hash] hash
    def from_hash(hash)
      hash.each_pair {|key, value| self.instance_variable_set(key,value) unless key.to_s.start_with?("_")}
    end

    # Validates that all instance variables for the object are not nil
    def validate_instance_vars
      flag = true
      self.instance_variables.each { |iv| flag = false if (self.instance_variable_get(iv) == nil && !iv.to_s.start_with?("@_")) }
      flag
    end

    # Returns the version number as [String] from ./conf/version
    # @return [String]
    def get_razor_version
      file = File.open("#{$razor_root}/conf/version", "rb")
      version = file.read
      file.close
      version
    end
  end
end