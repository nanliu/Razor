# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "object"

# Root Razor namespace
# @author Nicholas Weaver
module Razor

  # Root Razor::Node namespace
  # @author Nicholas Weaver
  class Node < Razor::Object
    attr_accessor :name
    attr_accessor :attributes_hash
    attr_accessor :timestamp
    attr_accessor :last_state
    attr_accessor :current_state
    attr_accessor :next_state
    attr_accessor :tags

    # init
    # @param hash [Hash]
    def initialize(hash)
      super()
      @_collection = :node
      @attributes_hash = {}
      from_hash(hash)
    end
  end
end