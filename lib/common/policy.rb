# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "object"

# Razor Policy class
# Used to apply Razor::Model to Razor::Node
module Razor
  class Policy < Razor::Object
    #noinspection RubyResolve
    attr_accessor :name


    attr_accessor :model
    attr_accessor :tag_matching


    attr_accessor :policy_type

    # @param hash [Hash]
    def initialize(hash)
      super()

      @model = nil
      @property_match = {}

      @_collection = :policy
      from_hash(hash)
    end



  end
end