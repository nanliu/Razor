# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# ProjectRazor Policy Base class
# Root abstract
module ProjectRazor
  module Policy
    class LinuxDeploy < ProjectRazor::Policy::Base
      attr_accessor :kernel_path


      # @param hash [Hash]
      def initialize(hash)
        super(hash)
        @policy_type = :standard

        from_hash(hash) unless hash == nil
      end


      def mk_call(node)
        # Placeholder - tell it to reboot
        logger.debug "Telling our node to reboot (placeholder)"
        [:reboot, {}]
      end
    end
  end
end