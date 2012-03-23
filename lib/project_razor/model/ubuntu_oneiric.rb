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

      attr_accessor :hostname

      def initialize(hash)
        super(hash)
        @hidden = false
        @model_type = :linux_deploy
        @name = "ubuntu_oneiric_min"
        @description = "Ubuntu Oneiric 11.10 Minimal"
        @hostname = nil

        @req_metadata_hash = {
            "@hostname" => {:default => "",
                            :example => "hostname.example.org",
                            :validation => '^[\w.]+$',
                            :required => true,
                            :description => "node hostname"}
        }


        @callback = {"preseed" => :generate_preseed}


        from_hash(hash) unless hash == nil
      end



      def generate_preseed (args_array)
        puts args_array.inspect
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
    end
  end
end