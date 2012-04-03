# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

module ProjectRazor
  module ImageService
    # Image construct for generic Operating System install ISOs
    class VMwareHypervisor < ProjectRazor::ImageService::Base

      attr_accessor :esxi_version


      def initialize(hash)
        super(hash)
        @description = "VMware Hypervisor Install"
        @path_prefix = "esxi"
        @hidden = false
        from_hash(hash) unless hash == nil
      end

      def add(src_image_path, image_svc_path, extra)
        begin
          resp = super(src_image_path, image_svc_path, extra)
          if resp[0]
            puts image_svc_path
          else
            resp
          end
        rescue => e
          logger.error e.message
          return [false, e.message]
        end

      end

      def verify(image_svc_path)
        super(image_svc_path)
      end

      def print_image_info(image_svc_path)
        super(image_svc_path)
        print "\tVersion: "
        print "#{@esxi_version}  \n".green
      end

    end
  end
end
