# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

module ProjectRazor
  module ImageService
    # Image construct for Microkernel files
    class MicroKernel < ProjectRazor::ImageService::Base
      attr_accessor :mk_version

      def initialize(hash)
        super(hash)
        from_hash(hash) unless hash == nil
      end

      def add(src_image_path, image_svc_path)
        # Add the iso to the image svc storage
        resp = super(src_image_path, image_svc_path)
        if resp[0]
          # TODO - Get a metadata file in the root of MK ISO for identifying the version
          # For now will parse the filename and pull the version out
          @mk_version = /[0-9]\.[0-9]\.[0-9]\.[0-9]/.match(@filename).to_s
        end
        resp
      end

      def verify(image_svc_path)
        # TODO add check for MK metadata file
        File.exist?(image_path(image_svc_path) + "/core.gz") && File.exist?(image_path(image_svc_path) + "/vmlinuz")
      end


    end
  end
end