# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# ProjectRazor Policy Base class
# Root abstract
module ProjectRazor
  module PowerControl
    class Bmc < ProjectRazor::Object
      attr_accessor :mac
      attr_accessor :ip

      # @param hash [Hash]
      def initialize(hash = nil)
        super()
        @_collection = :bmc
        from_hash(hash) unless hash == nil
        @ipmi = ProjectRazor::PowerControl::IpmiController.instance
      end

      def change_power_state(new_state, username, password)
        case new_state
          when new_state = "on"
            return ipmi.power_on(@ip, username, password)
          when new_state = "off"
            return ipmi.power_off(@ip, username, password)
          when new_state = "cycle"
            return ipmi.power_cycle(@ip, username, password)
          when new_state = "reset"
            return ipmi.power_reset(@ip, username, password)
          else
            return [false, "Unrecognized power-state #{new_state}; acceptable values are on, off, cycle, or reset"]
        end
      end

      def power_status(username, password)
        ipmi.power_status(@ip, username, password)
      end

      def bmc_info(username, password)
        ipmi.bmc_info(@ip, username, password)
      end

      def bmc_getenables(username, password)
        ipmi.bmc_getenables(@ip, username, password)
      end

      def bmc_guid(username, password)
        ipmi.bmc_guid(@ip, username, password)
      end

      def chassis_status(username, password)
        ipmi.chassis_status(@ip, username, password)
      end

      def lan_print(username, password)
        ipmi.lan_print(@ip, username, password)
      end

      def fru_print(username, password)
        ipmi.fru_print(@ip, username, password)
      end

    end
  end
end
