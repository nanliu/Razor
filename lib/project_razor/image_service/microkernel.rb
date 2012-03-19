# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "yaml"

module ProjectRazor
  module ImageService
    # Image construct for Microkernel files
    class MicroKernel < ProjectRazor::ImageService::Base
      attr_accessor :mk_version
      attr_accessor :kernel
      attr_accessor :initrd
      attr_accessor :iso_build_time
      attr_accessor :iso_version


      def initialize(hash)
        super(hash)
        @path_prefix = "mk"
        from_hash(hash) unless hash == nil
      end

      def add(src_image_path, image_svc_path)
        # Add the iso to the image svc storage
        begin
          resp = super(src_image_path, image_svc_path)
          if resp[0]

            if verify(image_svc_path)
              @iso_build_time = @meta['iso_build_time']
              @iso_version = @meta['iso_version']
              @kernel = @meta['kernel']
              @initrd = @meta['initrd']
            else
              logger.error "Missing metadata"
              return [false, "Missing metadata"]
            end
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
        if File.exist?("#{image_path}/iso-metadata.yaml")
          File.open("#{image_path}/iso-metadata.yaml","r") do
            |f|
            @meta = YAML.load(f)
          end


          unless File.exists?("#{image_path}/boot/#{@meta['kernel']}")
            logger.error "missing kernel: #{image_path}/boot/#{@meta['kernel']}"
            return false
          end

          unless File.exists?("#{image_path}/boot/#{@meta['initrd']}")
            logger.error "missing kernel: #{image_path}/boot/#{@meta['initrd']}"
            return false
          end

          if @meta['iso_build_time'] == nil
            logger.error "ISO build time is nil"
            return false
          end

          if @meta['iso_version'] == nil
            logger.error "ISO build time is nil"
            return false
          end

          true
        else
          logger.error "Missing metadata"
          false
        end
      end


    end
  end
end