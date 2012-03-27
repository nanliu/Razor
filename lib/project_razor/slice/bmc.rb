# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "yaml"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice Bmc
    # Used for all BMC/IPMI logic
    # @author Tom McSweeney
    class Bmc < ProjectRazor::Slice::Base
      include(ProjectRazor::Logging)
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:register => "register_bmc",
                           :get => "query_bmc",
                           :power_on => "power_on_bmc",
                           :power_off => "power_off_bmc",
                           :power_cycle => "power_cycle_bmc",
                           :power_reset => "power_reset_bmc",
                           :power_status => "power_status_bmc",
                           :bmc_info => "bmc_info_bmc",
                           :bmc_getenables => "bmc_getenables_bmc",
                           :bmc_guid => "bmc_guid_bmc",
                           :chassis_status => "chassis_status_bmc",
                           :lan_print => "lan_print_bmc",
                           :fru_print => "fru_print_bmc",
                           :default => "query_bmc"}
        @slice_commands_help = {:register => "bmc register (JSON STRING)",
                                :get => "bmc [get] (JSON STRING)",
                                :power_on => "bmc power_on (JSON STRING)",
                                :power_off => "bmc power_off (JSON STRING)",
                                :power_cycle => "bmc power_cycle (JSON STRING)",
                                :power_reset => "bmc power_reset (JSON STRING)",
                                :power_status => "power_status_bmc (JSON STRING)",
                                :bmc_info => "bmc_info_bmc (JSON STRING)",
                                :bmc_getenables => "bmc_getenables_bmc (JSON STRING)",
                                :bmc_guid => "bmc_guid_bmc (JSON STRING)",
                                :chassis_status => "chassis_status_bmc (JSON STRING)",
                                :lan_print => "lan_print_bmc (JSON STRING)",
                                :fru_print => "fru_print_bmc (JSON STRING)",
                                :default => "bmc [get] (JSON STRING)"}
        @slice_name = "Bmc"
        data = ProjectRazor::Data.new
        config = data.config
        @ipmi_username = config.default_ipmi_username
        @ipmi_password = config.default_ipmi_password
      end

      # Registers BMC NIC
      def register_bmc
        logger.debug "Register bmc called"
        @command_name = "register_bmc"
        if @web_command
          @command_query_string = @command_array.shift
          if @command_query_string == "{}"
            logger.error "Missing bmc details"
            slice_error("MissingDetails")
          else
            begin
              details = JSON.parse(@command_query_string)

              if details['@uuid'] != nil && details['@mac'] != nil && details['@ip'] != nil

                logger.debug "bmc: #{details['@mac']} #{details['@ip']}"
                details['@timestamp'] = Time.now.to_i
                new_bmc = insert_bmc(details)

                if new_bmc.refresh_self
                  slice_success(new_bmc.to_hash, false)
                else
                  logger.error "Could not register bmc"
                  slice_error("CouldNotRegister", false)
                end
              else
                logger.error "Incomplete bmc details"
                slice_error("IncompleteDetails", false)
              end
            rescue StandardError => e
              slice_error(e.message, false)
            end
          end
        end
      end

      # Power on a node (that is already off)
      def power_on_bmc
        logger.debug "Power_On bmc called"
        @command_name = "power_on_bmc"
        change_bmc_power_state("on")
      end

      # Power off a node (that is already on)
      def power_off_bmc
        logger.debug "Power_On bmc called"
        @command_name = "power_off_bmc"
        change_bmc_power_state("off")
      end

      # Power-cycle a node (that is already on)
      def power_cycle_bmc
        logger.debug "Power_On bmc called"
        @command_name = "power_cycle_bmc"
        change_bmc_power_state("cycle")
      end

      # Perform a hard-reset on a node (that is already on)
      def power_reset_bmc
        logger.debug "Power_On bmc called"
        @command_name = "power_reset_bmc"
        change_bmc_power_state("reset")
      end

      # Run an ipmitool "fru_print" on the node
      def power_status_bmc
        logger.debug "ipmitool 'power_status' called"
        @command_name = "power_status_bmc"
        run_ipmi_query_cmd("power_status")
      end

      # Run an ipmitool "fru_print" on the node
      def bmc_info_bmc
        logger.debug "ipmitool 'bmc_info' called"
        @command_name = "bmc_info_bmc"
        run_ipmi_query_cmd("bmc_info")
      end

      # Run an ipmitool "fru_print" on the node
      def bmc_getenables_bmc
        logger.debug "ipmitool 'bmc_getenables' called"
        @command_name = "bmc_getenables_bmc"
        run_ipmi_query_cmd("bmc_getenables")
      end

      # Run an ipmitool "fru_print" on the node
      def bmc_guid_bmc
        logger.debug "ipmitool 'bmc_guid' called"
        @command_name = "bmc_guid_bmc"
        run_ipmi_query_cmd("bmc_guid")
      end

      # Run an ipmitool "fru_print" on the node
      def chassis_status_bmc
        logger.debug "ipmitool 'chassis_status' called"
        @command_name = "chassis_status_bmc"
        run_ipmi_query_cmd("chassis_status")
      end

      # Run an ipmitool "fru_print" on the node
      def lan_print_bmc
        logger.debug "ipmitool 'lan_print' called"
        @command_name = "lan_print_bmc"
        run_ipmi_query_cmd("lan_print")
      end

      # Run an ipmitool "fru_print" on the node
      def fru_print_bmc
        logger.debug "ipmitool 'fru_print' called"
        @command_name = "fru_print_bmc"
        run_ipmi_query_cmd("fru_print")
      end

      def run_ipmi_query_cmd(ipmitool_cmd)
        if @web_command
          @command_query_string = @command_array.shift
          if @command_query_string == "{}"
            logger.error "Missing bmc details"
            slice_error("MissingDetails")
          else
            begin
              details = JSON.parse(@command_query_string)
              if details['@uuid'] != nil
                logger.debug "Running ipmi_query command #{ipmitool_cmd} on bmc: #{details['@uuid']}"
                details['@timestamp'] = Time.now.to_i
                bmc = get_bmc(details)
                command_matched, output = bmc.run_ipmi_query_cmd(ipmitool_cmd, @ipmi_username, @ipmi_password)
                # handle the returned values;
                if command_matched
                  p output
                else
                  logger.error "No command matching #{ipmitool_cmd} supported by Bmc object"
                  slice_error("CouldNotPowerOn", false)
                end
              else
                logger.error "Incomplete bmc details"
                slice_error("IncompleteDetails", false)
              end
            rescue StandardError => e
              slice_error(e.message, false)
            end
          end
        end
      end

      # Handler for changing power state of a bmc node to a new state
      # @param [String] new_state
      #
      # Possible values for the new_state parameter are as follows:
      #
      #     "on"    =>  Powers on the node
      #     "off"   =>  Powers off the node
      #     "cycle" => Power cycles the node
      #     "reset" => Performs a hard reset of the node
      #
      # This method is meant to be invoked from the various commands provided by
      # the slice to change the power-state of the node
      def change_bmc_power_state(new_state)
        if @web_command
          @command_query_string = @command_array.shift
          if @command_query_string == "{}"
            logger.error "Missing bmc details"
            slice_error("MissingDetails")
          else
            begin
              details = JSON.parse(@command_query_string)
              if details['@uuid'] != nil
                logger.debug "Changing power-state of bmc: #{details['@uuid']} to #{new_state}"
                details['@timestamp'] = Time.now.to_i
                bmc = get_bmc(details)
                power_state_changed, status_string = bmc.change_power_state(@ipmi_username, @ipmi_password)
                # handle the returned values; how the returned values should be handled will vary
                # depending on the "new_state" that the node is being transitioned into.  For example,
                # you can only turn on a node that is off (or turn off a node that is on), but it
                # isn't an error to turn on a node that is already on (or turn off a node that is
                # already off) since that operation is, in effect, a no-op.  On the other hand,
                # it is an error to try to power-cycle or reset a node that isn't already on, since
                # these operations don't make any sense on a powered-off node.
                case new_state
                  when new_state = "on"
                    if power_state_changed && /Up\/On/.matches(status_string)
                      slice_success("Node #{details['@uuid']} now powering on", false)
                    elsif !power_state_changed && /Up\/On/.matches(status_string)
                      slice_success("Node #{details['@uuid']} already powered on", false)
                    else
                      logger.error "Could not power on bmc"
                      slice_error("CouldNotPowerOn", false)
                    end
                  when new_state = "off"
                    if power_state_changed && /Down\/Off/.matches(status_string)
                      slice_success("Node #{details['@uuid']} now powering off", false)
                    elsif !power_state_changed && /Down\/Off/.matches(status_string)
                      slice_success("Node #{details['@uuid']} already powered off", false)
                    else
                      logger.error "Could not power off bmc"
                      slice_error("CouldNotPowerOff", false)
                    end
                  when new_state = "cycle"
                    if power_state_changed && /Cycle/.matches(status_string)
                      slice_success("Node #{details['@uuid']} now power cycling", false)
                    elsif !power_state_changed && /Off/.matches(status_string)
                      slice_error("Node #{details['@uuid']} powered off, cannot power cycle", false)
                    else
                      logger.error "Could not power off bmc"
                      slice_error("CouldNotPowerOff", false)
                    end
                  when new_state = "reset"
                    if power_state_changed && /Reset/.matches(status_string)
                      slice_success("Node #{details['@uuid']} now powering off", false)
                    elsif !power_state_changed && /Off/.matches(status_string)
                      slice_error("Node #{details['@uuid']} powered off, cannot reset", false)
                    else
                      logger.error "Could not power off bmc"
                      slice_error("CouldNotPowerOff", false)
                    end
                end
              else
                logger.error "Incomplete bmc details"
                slice_error("IncompleteDetails", false)
              end
            rescue StandardError => e
              slice_error(e.message, false)
            end
          end
        end
      end

      def update_bmc_hash!(bmc, bmc_hash)
        begin
          status_flag, power_state = bmc.run_ipmi_query_cmd("power_status", @ipmi_username, @ipmi_password)
          bmc_hash["@current_power_state"] = power_state if status_flag
          status_flag, fru_hash = bmc.run_ipmi_query_cmd("fru_print", @ipmi_username, @ipmi_password)
          bmc_hash["@board_serial_number"] = fru_hash[:Board_Serial] if status_flag
        rescue => e
          bmc_hash["@current_power_state"] = "unknown"
          bmc_hash["@board_serial_number"] = ''
        end
      end

      # Inserts bmc using hash
      # @param [Hash] bmc_hash
      # @return [ProjectRazor::Bmc]
      def insert_bmc(bmc_hash)
        setup_data
        bmc = @data.fetch_object_by_uuid(:bmc, bmc_hash['@uuid'])
        if bmc != nil
          update_bmc_hash!(bmc, bmc_hash)
          if bmc.mac != bmc_hash['@mac'] || bmc.ip != bmc_hash['@ip'] ||
              bmc.current_power_state != bmc_hash['@current_power_state'] ||
              bmc.board_serial_number != bmc_hash['@board_serial_number']
            bmc.mac = bmc_hash['@mac']
            bmc.ip = bmc_hash['@ip']
            bmc.current_power_state = "unknown"
            bmc.board_serial_number = ''
            begin
              status_flag, power_state = bmc.run_ipmi_query_cmd("power_status", @ipmi_username, @ipmi_password)
              bmc.current_power_state = power_state if status_flag
              status_flag, fru_hash = bmc.run_ipmi_query_cmd("fru_print", @ipmi_username, @ipmi_password)
              bmc.board_serial_number = fru_hash[:Board_Serial] if status_flag
            rescue => e
              bmc.current_power_state = "unknown"
              bmc.board_serial_number = ''
            end
            bmc.update_self
          end
          bmc
        else
          bmc = ProjectRazor::PowerControl::Bmc.new(bmc_hash)
          begin
            status_flag, power_state = bmc.run_ipmi_query_cmd("power_status", @ipmi_username, @ipmi_password)
            bmc.current_power_state = power_state if status_flag
            status_flag, fru_hash = bmc.run_ipmi_query_cmd("fru_print", @ipmi_username, @ipmi_password)
            bmc.board_serial_number = fru_hash[:Board_Serial] if status_flag
          rescue => e
            bmc.current_power_state = "unknown"
            bmc.board_serial_number = ''
          end
          @data.persist_object(bmc)
          bmc
        end
      end

      def get_bmc(bmc_hash)
        setup_data
        existing_bmc = @data.fetch_object_by_uuid(:bmc, bmc_hash['@uuid'])
      end

      def query_bmc
        print_bmc get_object("bmc", :bmc)
      end

      # Handles printing of bmc details to CLI or REST
      # @param [Hash] bmc_array
      def print_bmc(bmc_array)
        unless @web_command
          puts "BMC:"

          unless @verbose
            bmc_array.each do
            |bmc|
              power_state = ''
              board_no = ''
              begin
                status_flag, power_state = bmc.run_ipmi_query_cmd("power_status", @ipmi_username, @ipmi_password)
                status_flag, fru_hash = bmc.run_ipmi_query_cmd("fru_print", @ipmi_username, @ipmi_password)
                board_no = fru_hash[:Board_Serial] if status_flag
              rescue
                power_state = "unknown"
                board_no = ''
              end
              case power_state
                when "on"
                  puts "    uuid: #{bmc.uuid}   mac: #{bmc.mac}   ip: #{bmc.ip}   s/n: #{board_no}".green
                when "off"
                  puts "    uuid: #{bmc.uuid}   mac: #{bmc.mac}   ip: #{bmc.ip}   s/n: #{board_no}".red
                else
                  puts "    uuid: #{bmc.uuid}   mac: #{bmc.mac}   ip: #{bmc.ip}   s/n: #{board_no}".yellow
              end
            end
          else
            bmc_array.each do
            |bmc|
              bmc.instance_variables.each do
              |iv|
                unless iv.to_s.start_with?("@_")
                  key = iv.to_s.sub("@", "")
                  print "#{key}: "
                  print "#{bmc.instance_variable_get(iv)}  ".green
                end
              end
              print "\n"
            end
          end
        else
          bmc_array = bmc_array.collect { |bmc| bmc.to_hash }
          slice_success(bmc_array, false)
        end
      end

    end
  end
end
