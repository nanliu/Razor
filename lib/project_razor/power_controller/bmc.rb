# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# ProjectRazor Policy Base class
# Root abstract
module ProjectRazor
  module PowerController
    class Bmc < ProjectRazor::Object
      attr_accessor :mac
      attr_accessor :ip

      # @param hash [Hash]
      def initialize(hash)
        super()
        @_collection = :bmc
        @attributes_hash = {}
        from_hash(hash)
      end

      # These are required methods called by the engine for all policies

      # Called when a MK does a checkin from a bmc bound to this policy
      def mk_call(bmc)
        # This is our base model - we have nothing to do so we just tell the MK : acknowledge
        [:acknowledge, {}]
      end

      # Called from a bmc bound to this policy does a boot and requires a script
      def boot_call(bmc)

      end

      # Called from either REST slice call by bmc or daemon doing polling
      def state_call(bmc, new_state)

      end


      # Placeholder - may be removed and used within state_call
      # intended to be called by bmc or daemon for connection/hand-off to systems
      def system_call(bmc, new_state)

      end

    end
  end
end
