# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "fileutils"

module ProjectRazor
  module ImageService
    # Base image abstract
    class Base < ProjectRazor::Object

      attr_accessor :filename
      attr_accessor :description
      attr_accessor :size

      def initialize(hash)
        super()
        from_hash(hash) unless hash == nil
      end


      # Used to add an image to the service
      # Within each child class the methods are overridden for that child type
      def add(src_image_path, image_svc_path)
        begin

          # Get full path
          fullpath = File.expand_path(src_image_path)
          # Get filename
          @filename = File.basename(fullpath)

          puts "fullpath: #{fullpath}".red
          puts "filename: #{@filename}".red
          puts "mount path: #{mount_path}".red


          # Make sure file exists

          return cleanup([false,"File does not exist"]) unless File.exist?(fullpath)

          # Make sure it has an .iso extension
          return cleanup([false,"File is not an ISO"]) if @filename[-4..-1] != ".iso"




          # Confirm a mount doesn't already exist
          if is_mounted?(fullpath)
            puts "already mounted"
          else
            puts "not mounted"
            unless mount(fullpath)
              logger.error "Could not mount #{fullpath} on #{mount_path}"
              return cleanup([false,"Could not mount"])
            end
          end


            # Determine if there is an existing image path
            ## Remove if there is
            ## Create image path

            # Attempt to copy from mount path to image path

            # Verify diff between mount / image paths

            # Verify using verify method

            # Run unmount cleanup

            # Return result


        rescue => e
          logger.error e.message
          return cleanup([false,e.message])
        end


        cleanup([true ,""])
      end

      # Used to remove an image to the service
      # Within each child class the methods are overridden for that child type
      def remove

      end

      # Used to verify an image within the filesystem (local/remote/possible Glance)
      # Within each child class the methods are overridden for that child type
      def verify

      end

      def image_path(image_svc_path)
        image_svc_path + "/" + filename
      end

      def is_mounted?(src_image_path)
        mounts.each do
        |mount|
          return true if mount[0] == src_image_path && mount[1] == mount_path
        end
        false
      end

      def mount(src_image_path)
        FileUtils.mkpath(mount_path) unless Dir.exist?(mount_path)

        `mount -o loop #{src_image_path} #{mount_path} 2> /dev/null`
        if $?.to_i == 0
          true
        else
          false
        end
      end

      def umount
        `umount #{mount_path} 2> /dev/null`
        if $? == 0
          true
        else
          false
        end
      end

      def copy_iso_to_image

      end

      def verify_copy

      end

      def mounts
        `mount`.split("\n").map! {|x| x.split("on")}.map! {|x| [x[0],x[1].split(" ")[0]]}
      end

      def cleanup(ret)
        umount
        FileUtils.rm_r(mount_path, :force => true) if Dir.exist?(mount_path)
        ret
      end

      def mount_path
        "#{$temp_path}/#{@uuid}"
      end

    end
  end
end