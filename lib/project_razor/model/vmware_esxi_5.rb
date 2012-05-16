# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module ModelTemplate
    # Root Model object
    # @author Nicholas Weaver
    # @abstract
    class VMwareESXi5 < ProjectRazor::ModelTemplate::VMwareESXi

      def initialize(hash)
        super(hash)
        # Static config
        @hidden = false
        @name = "vmware_esxi_5"
        @description = "VMware ESXi 5 Deployment"
        @osversion = "5"
        from_hash(hash) unless hash == nil
      end
    end
  end
end
