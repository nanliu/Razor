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
"d-i debian-installer/locale string en_US
d-i console-setup/ask_detect boolean false
d-i console-setup/layoutcode string us

d-i netcfg/choose_interface select auto

d-i netcfg/get_hostname string unassigned-hostname
d-i netcfg/get_domain string unassigned-domain


d-i mirror/protocol string http
d-i mirror/country string manual
d-i mirror/http/hostname string #{config.image_svc_host}:#{config.image_svc_port}
d-i mirror/http/directory string /razor/image/#{@image_uuid}
d-i mirror/http/proxy string
d-i mirror/suite string oneiric

d-i clock-setup/utc boolean true

d-i time/zone string US/Eastern

# Suggest LVM by default.

d-i partman-auto/disk string /dev/sda
d-i partman-auto/method string lvm

d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true"




      end

      def nl(s)
        s + "\n"
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


      def mk_call(node, policy)
        @node_bound = node
        @policy_bound = policy


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

      def boot_call(node, policy)
        @node_bound = node
        @policy_bound = policy

        ip = "#!ipxe\n"
        ip << "echo Reached #{@label} model boot_call\n"
        ip << "echo Our image UUID is: #{@image_uuid}\n"
        ip << "echo Our state is: #{@current_state}\n"
        ip << "echo Our node UUID: #{@node_bound.uuid}\n"
        ip << "\n"
        ip << "kernel #{image_svc_uri}/#{@image_uuid}/#{kernel_path} #{kernel_args}  || goto error\n"
        ip << "initrd #{image_svc_uri}/#{@image_uuid}/#{initrd_path} || goto error\n"
        ip << "boot\n"
        ip
      end


      def boot_install_script
        #boot_script = ""
        #boot_script << "#!ipxe\n"
        #boot_script << "kernel #{image_svc_uri}/#{@image_uuid}/#{kernel_path} preseed/url= || goto error\n"
        #boot_script << "initrd #{image_svc_uri}/#{@image_uuid}/#{initrd_path} || goto error\n"
        #boot_script << "boot || goto error\n"
        #boot_script << "\n\n\n"
        #boot_script << ":error\necho ERROR, will reboot in #{config.mk_checkin_interval}\nsleep #{config.mk_checkin_interval}\nreboot\n"
        #boot_script
      end

      def kernel_args
        ka = ""
        ka << "preseed/url=#{api_svc_uri}/policy/callback/#{@policy_bound.uuid}/preseed/file "
        ka << "debian-installer/locale=en_US "
        ka << "netcfg/choose_interface=auto "
        ka << "priority=critical "
        ka
      end

      def kernel_path
        "install/netboot/ubuntu-installer/amd64/linux"
      end

      def initrd_path
        "install/netboot/ubuntu-installer/amd64/initrd.gz"
      end

      def config
        $data.config
      end

      def image_svc_uri
        "http://#{config.image_svc_host}:#{config.image_svc_port}/razor/image"
      end

      def api_svc_uri
        "http://#{config.image_svc_host}:#{config.api_port}/razor/api"
      end


    end
  end
end