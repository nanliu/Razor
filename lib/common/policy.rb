# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

Dir.glob(ENV['RAZOR_HOME'] + '/lib/**/').each {|x| $LOAD_PATH << x} # adds Razor lib/dirs to load path


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