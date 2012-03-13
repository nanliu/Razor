# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# ProjectRazor Policy Base class
# Root abstract
module ProjectRazor
  module PowerControl
    class Bmc < ProjectRazor::Object
      attr_accessor :mac
      attr_accessor :ip

      # @param hash [Hash]
      def initialize(hash = nil)
        super()
        @_collection = :bmc
        from_hash(hash) unless hash == nil
      end

    end
  end
end
