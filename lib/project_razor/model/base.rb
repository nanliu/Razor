# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Model
    # Root Model object
    # @author Nicholas Weaver
    # @abstract
    class Base < ProjectRazor::Object
      attr_accessor :name
      attr_accessor :model_type
      attr_accessor :model_description
      attr_accessor :values_hash

      # init
      # @param hash [Hash]
      def initialize(hash)
        @name = "Base Model(hidden)"
        @model_type = :base
        @model_description = "Base model type"
        @values_hash = {}
        super()
        @_collection = :model
        from_hash(hash) unless hash == nil
      end


      def define_values_hash
        @values_hash = {} #
      end
    end
  end
end
