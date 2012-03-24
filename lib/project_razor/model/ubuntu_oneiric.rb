# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Model
    # Root Model object
    # @author Nicholas Weaver
    # @abstract
    class UbuntuOneiricMinimal < ProjectRazor::Model::Base

      # Assigned image
      attr_accessor :image_uuid

      # Metadata
      attr_accessor :hostname

      # Compatible Image Prefix
      attr_accessor :image_prefix


      def initialize(hash)
        super(hash)

        # Static config
        @hidden = false
        @model_type = :linux_deploy
        @name = "ubuntu_oneiric_min"
        @description = "Ubuntu Oneiric 11.10 Minimal"

        # Metadata vars
        @hostname = nil

        # State / must have a starting state
        @current_state = :init

        # Image UUID
        @image_uuid = true

        # Image prefix we can attach
        @image_prefix = "os"


        @req_metadata_hash = {
            "@hostname" => {:default => "",
                            :example => "hostname.example.org",
                            :validation => '^[\w.]+$',
                            :required => true,
                            :description => "node hostname"}
        }


        @callback = {"preseed" => :preseed_call}


        from_hash(hash) unless hash == nil
      end



      def preseed_call (args_array)
        @arg = args_array.shift

        case @arg

          when  "start"
            fsm_action(:preseed_start)
            return "ok"

          when "end"
            fsm_action(:preseed_end)
            return "ok
"
          when "file"
            fsm_action(:preseed_action)
            return generate_preseed

          else
            return "error"
        end

      end


      def generate_preseed
        ps = ""
        ps << '# Suggest LVM by default.'
        ps << 'd-i	partman-auto/init_automatically_partition	string some_device_lvm'
        ps << 'd-i	partman-auto/init_automatically_partition	seen false'
        ps << '# Always install the server kernel.'
        ps << 'd-i	base-installer/kernel/override-image	string linux-server'
        ps << '# Only install basic language packs. Let tasksel ask about tasks.'
        ps << 'd-i	pkgsel/language-pack-patterns	string'
        ps << '# No language support packages.'
        ps << 'd-i	pkgsel/install-language-support	boolean false'
        ps << '# Only ask the UTC question if there are other operating systems installed.'
        ps << 'd-i	clock-setup/utc-auto	boolean true'
        ps << '# Verbose output and no boot splash screen.'
        ps << 'd-i	debian-installer/quiet	boolean false'
        ps << 'd-i	debian-installer/splash	boolean false'
        ps << '# Install the debconf oem-config frontend (if in OEM mode).'
        ps << 'd-i	oem-config-udeb/frontend	string debconf'
        ps << '# Wait for two seconds in grub'
        ps << 'd-i	grub-installer/timeout	string 2'
        ps << '# Add the network and tasks oem-config steps by default.'
        ps << 'oem-config	oem-config/steps	multiselect language, timezone, keyboard, user, network, tasks'
        ps
      end


      # Defines our FSM for this model
      #  For state => {action => state, ..}
      def fsm
        {
            :init => {:mk_call => :init,
                      :boot_call => :init,
                      :preseed_start => :preinstall,
                      :preseed_file => :init,
                      :preseed_end => :postinstall,
                      :timeout => :timeout_error,
                      :error => :error_catch,
                      :else => :init},
            :preinstall => {:mk_call => :preinstall,
                            :boot_call => :preinstall,
                            :preseed_start => :preinstall,
                            :preseed_file => :init,
                            :preseed_end => :postinstall,
                            :preseed_timeout => :timeout_error,
                            :error => :error_catch,
                            :else => :preinstall},
            :postinstall => {:mk_call => :postinstall,
                             :boot_call => :postinstall,
                             :post_ok => :postinstall,
                             :post_error => :error_catch,
                             :post_timeout => :timeout_error,
                             :error => :error_catch,
                             :else => :error_catch},
            :os_validate => {:mk_call => :os_validate,
                             :boot_call => :os_validate,
                             :os_ok => :os_complete,
                             :os_error => :os_error,
                             :os_timeout => :timeout_error,
                             :error => :error_catch,
                             :else => :error_catch},
            :os_complete => {:mk_call => :os_complete,
                             :boot_call => :os_complete,
                             :else => :os_complete,
                             :reset => :init},
            :timeout_error => {:mk_call => :timeout_error,
                               :boot_call => :timeout_error,
                               :else => :timeout_error,
                               :reset => :init},
            :error_catch => {:mk_call => :error_catch,
                             :boot_call => :error_catch,
                             :else => :error_catch,
                             :reset => :init},
        }
      end


      def mk_call(node)
        @node_bound = node


        case @current_state

          # We need to reboot
          when :init, :preinstall, :postinstall, :os_validate, :os_complete
            ret = [:reboot, {}]
          when :timeout_error, :error_catch
            ret = [:acknowledge, {}]
          else
            ret = [:acknowledge, {}]
        end

        fsm_action(:mk_call)
        ret
      end

      def boot_call(node)
        @node_bound = node
        ip << 'echo Reached #{label} model boot_call'
        ip << 'shel'
        ip
      end


    end
  end
end