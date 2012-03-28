# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# ProjectRazor Policy Base class
# Root abstract

module ProjectRazor
  module PowerControl
    class Bmc < ProjectRazor::Object
      attr_accessor :mac
      attr_accessor :ip
      attr_accessor :current_power_state
      attr_accessor :board_serial_number

      # @param hash [Hash]
      def initialize(hash = nil)
        super()
        @_collection = :bmc
        @current_power_state = "unknown"
        @board_serial_number = ''
        from_hash(hash) unless hash == nil
        @_ipmi = ProjectRazor::PowerControl::IpmiController.instance
        data = ProjectRazor::Data.new
        config = data.config
        @_ipmi_username = config.default_ipmi_username
        @_ipmi_password = config.default_ipmi_password
      end

      def change_power_state(new_state, username, password, ipmi_timeout = EXT_COMMAND_TIMEOUT)
        case new_state
          when new_state = "on"
            return @_ipmi.power_on(@ip, username, password)
          when new_state = "off"
            return @_ipmi.power_off(@ip, username, password)
          when new_state = "cycle"
            return @_ipmi.power_cycle(@ip, username, password)
          when new_state = "reset"
            return @_ipmi.power_reset(@ip, username, password)
          else
            return [false, "Unrecognized power-state #{new_state}; acceptable values are on, off, cycle, or reset"]
        end
      end

      def run_ipmi_query_cmd(cmd, username, password)
        case cmd
          when "power_status"
            return @_ipmi.power_status(@ip, username, password)
          when "bmc_info"
            return @_ipmi.bmc_info(@ip, username, password)
          when "bmc_getenables"
            return @_ipmi.bmc_getenables(@ip, username, password)
          when "bmc_guid"
            return @_ipmi.bmc_guid(@ip, username, password)
          when "chassis_status"
            return @_ipmi.chassis_status(@ip, username, password)
          when "lan_print"
            return @_ipmi.lan_print(@ip, username, password)
          when "fru_print"
            return @_ipmi.fru_print(@ip, username, password)
          else
            return [false, "Unrecognized query command #{cmd}; acceptable values are power_status," +
                " bmc_info, bmc_getenables, bmc_guid, chassis_status, lan_print or fru_print"]
        end
      end

      def print_header
        return "UUID", "IP-Addr", "MAC-Addr", "S/N"
      end

      def print_items
        return @uuid, @ip, @mac, @board_serial_number
      end

      def line_color
        case @current_power_state
          when "on"
            return :green
          when "off"
            return :red
          else
            return :yellow
        end
      end

      def header_color
        :white
      end

    end
  end
end
