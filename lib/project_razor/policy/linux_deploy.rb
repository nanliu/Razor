# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# ProjectRazor Policy Base class
# Root abstract
module ProjectRazor
  module Policy
    class LinuxDeploy < ProjectRazor::Policy::Base
      attr_accessor :kernel_path
      attr_accessor :line_number
      attr_accessor :model
      attr_accessor :tags
      attr_accessor :active
      attr_reader :policy_type
      attr_reader :model_type

      # @param hash [Hash]
      def initialize
        super
        @active = false
        @line_number = -1
        @model = nil
        @tags = []
        @policy_type = :hidden
        @model_type = []

        @_collection = :policy
      end
    end
  end
end