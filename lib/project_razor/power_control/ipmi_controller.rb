# IpmiController Class; a simple wrapper around the ipmitool interface that provides
# a mechanism for gathering information from an underlying BMC using the BMC's IPMI
# interface
#
# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved
#
#@author Tom McSweeney

require 'singleton'

module ProjectRazor
  module PowerControl
    class IpmiController < ProjectRazor::Object

      include Singleton

      # First, define a set of 'query-style' actions that will invoke corresponding
      # commands from the ipmitool command set
      def power_status(host_ip, username, passwd)
        power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'status')
        power_output = power_output.split("\n")
        power_status = /.*(on|off)$/.match(power_output[0])[1]
      end

      def bmc_info(host_ip, username, passwd)
        bmc_output = run_ipmi_command(host_ip, username, passwd, 'bmc', 'info')
        bmc_hash = impi_output_to_hash(bmc_output, ':')
      end

      def bmc_getenables(host_ip, username, passwd)
        bmc_output = run_ipmi_command(host_ip, username, passwd, 'bmc', 'getenables')
        bmc_hash = impi_output_to_hash(bmc_output, ':')
      end

      def bmc_guid(host_ip, username, passwd)
        bmc_output = run_ipmi_command(host_ip, username, passwd, 'bmc', 'guid')
        bmc_hash = impi_output_to_hash(bmc_output, ':')
      end

      def chassis_status(host_ip, username, passwd)
        chassis_output = run_ipmi_command(host_ip, username, passwd, 'chassis', 'status')
        chassis_hash = impi_output_to_hash(chassis_output, ':')
      end

      def lan_print(host_ip, username, passwd)
        lan_output = run_ipmi_command(host_ip, username, passwd, 'lan', 'print')
        lan_hash = impi_output_to_hash(lan_output, ':')
      end

      def fru_print(host_ip, username, passwd)
        fru_output = run_ipmi_command(host_ip, username, passwd, 'fru', 'print')
        fru_hash = impi_output_to_hash(fru_output, ':')
      end

      # Then, define a set of 'command-style' actions that will invoke corresponding
      # actions from the ipmitool command set (power on, power off, power cycle, )

      def power_on(host_ip, username, passwd)
        power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'status')
        power_output = power_output.split("\n")
        power_status = /.*(on|off)$/.match(power_output[0])[1]
        if power_status == 'off'
          power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'on')
          power_output = power_output.split("\n")
          return [true, /.*(Up\/On)$/.match(power_output[0])[1]]
        end
        [false, 'Up/On']
      end

      def power_off(host_ip, username, passwd)
        power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'status')
        power_output = power_output.split("\n")
        power_status = /.*(on|off)$/.match(power_output[0])[1]
        if power_status == 'on'
          power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'off')
          power_output = power_output.split("\n")
          return [true, /.*(Down\/Off)$/.match(power_output[0])[1]]
        end
        [false, 'Down/Off']
      end

      def power_cycle(host_ip, username, passwd)
        power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'status')
        power_output = power_output.split("\n")
        power_status = /.*(on|off)$/.match(power_output[0])[1]
        if power_status == 'on'
          power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'cycle')
          power_output = power_output.split("\n")
          return [true, /.*(Cycle)$/.match(power_output[0])[1]]
        end
        [false, 'Off']
      end

      def power_reset(host_ip, username, passwd)
        power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'status')
        power_output = power_output.split("\n")
        power_status = /.*(on|off)$/.match(power_output[0])[1]
        if power_status == 'on'
          power_output = run_ipmi_command(host_ip, username, passwd, 'power', 'reset')
          power_output = power_output.split("\n")
          return [true, /.*(Reset)$/.match(power_output[0])[1]]
        end
        [false, 'Off']
      end

      private

      def run_ipmi_command(host_ip, username, passwd, *cmd_and_args)
        command_str = cmd_and_args.join(' ')
        %x[ipmitool -I lanplus -H #{host_ip} -U #{username} -P #{passwd} #{command_str}]
      end

      def impi_output_to_hash(impi_output, delimiter)
        array = impi_output.split("\n")
        split_hash = Hash.new
        delimiter = "\\#{delimiter}"
        prev_key = nil
        index = 0
        begin
          # grab the next entry
          entry = array[index]
          (index += 1; next) if entry.strip.length == 0
          # parse that entry to obtain the key, first by splitting on the delimiter, then
          # by replacing characters that could be problematic in a symbol with other
          # characters, and finally by converting the key into a symbol
          key_str = entry.split(/\s*#{delimiter}\s?/)[0].strip.gsub(/\s+/," ").gsub(' ','_').gsub('.','').gsub(/^#/,"number")
          # if the key value parsed above is an empty string, then this line contains a value for a
          # key that was parsed earlier
          if key_str.length == 0 && prev_key
            # construct the current value (should be a non-zero-length string)
            val = entry.split(/\s*#{delimiter}\s?/,2)[1].strip
            # grab the value that is mapped to the previous key
            val_to_modify = split_hash[prev_key]
            # if it is an array, simply append a new value to it, else create an array to hold
            # this value and the value mapped to by the prev_key value
            if val_to_modify.is_a?(Array)
              split_hash[prev_key] = (val_to_modify << val)
            else
              new_val = [val_to_modify, val]
              split_hash[prev_key] = new_val
            end
            # and move on to the next line in the array
            index += 1
          else
            key = key_str.to_sym
            # next, split the entry on the delimiter again, this time to determine the value that goes
            # with the key that we just constructed
            entry_array = entry.split(/\s*#{delimiter}\s?/,2)
            # if the length is two, we may or may not have a key-value pair (if the value is an empty string,
            # then we'll have to do a bit more work to get the "value", more on that in a bit)
            if (entry_array.length == 2)
              val = entry.split(/\s*#{delimiter}\s?/,2)[1].strip
              # if the value is non-zero-length string, then are looking at a name/value pair,
              # else if the value is a zero-length string, then assume that we have a set of values
              # in the lines that follow the current entry that contain the values that go with the
              # current key
              if val.length > 0 && index < array.length
                split_hash[key] = val
                index += 1
              elsif index < (array.length - 1)
                val_array = []
                # loop through the next values until hit the end of the array or find an entry
                # that has a length that is not equal to 1
                index += 1
                while index < array.length && (entry_array = array[index].split(/\s*#{delimiter}\s?/,2)).length == 1
                  # strip the single value in the entry_array and add it to the value array
                  val = entry_array[0].strip
                  val_array << val
                  index += 1
                end
                # add the value array as the value for this key in the hash map
                split_hash[key] = val_array
              end
            end
            prev_key = key
          end
        end while index < array.length
        return split_hash
      end

    end
  end
end
