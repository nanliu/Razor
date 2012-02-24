# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "object"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Model
  # Root Model object
  # @author Nicholas Weaver
  # @abstract
  class Base < Razor::Object
    attr_accessor :name
    attr_accessor :model_type
    attr_accessor :model_description
    attr_accessor :values_hash

    # init
    # @param hash [Hash]
    def initialize(hash)
      @name = nil
      @model_type = :base
      @model_description = "Base model type"
      @values_hash = {}
      super()
      @_collection = :model
      from_hash(hash) unless hash == nil
    end


    def define_values_hash
      @values_hash = {
          :hostname => "",
          :root_account => "",
          :root_password => "",
          :ssh_pub_key => ""
      }
    end
  end
end