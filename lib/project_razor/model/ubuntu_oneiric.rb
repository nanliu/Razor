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


        @callback = {:preseed => :generate_preseed}


        from_hash(hash) unless hash == nil
      end



      def generate_preseed
        p = ""
        p << '# Suggest LVM by default.'
        p << 'd-i	partman-auto/init_automatically_partition	string some_device_lvm'
        p << 'd-i	partman-auto/init_automatically_partition	seen false'
        p << '# Always install the server kernel.'
        p << 'd-i	base-installer/kernel/override-image	string linux-server'
        p << '# Only install basic language packs. Let tasksel ask about tasks.'
        p << 'd-i	pkgsel/language-pack-patterns	string'
        p << '# No language support packages.'
        p << 'd-i	pkgsel/install-language-support	boolean false'
        p << '# Only ask the UTC question if there are other operating systems installed.'
        p << 'd-i	clock-setup/utc-auto	boolean true'
        p << '# Verbose output and no boot splash screen.'
        p << 'd-i	debian-installer/quiet	boolean false'
        p << 'd-i	debian-installer/splash	boolean false'
        p << '# Install the debconf oem-config frontend (if in OEM mode).'
        p << 'd-i	oem-config-udeb/frontend	string debconf'
        p << '# Wait for two seconds in grub'
        p << 'd-i	grub-installer/timeout	string 2'
        p << '# Add the network and tasks oem-config steps by default.'
        p << 'oem-config	oem-config/steps	multiselect language, timezone, keyboard, user, network, tasks'
        p
      end
    end
  end
end