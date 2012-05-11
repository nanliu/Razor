# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "yaml"

# time to wait for an external command (in milliseconds)
EXT_COMMAND_TIMEOUT = 2000

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
      # @param args [Array]
      def initialize(args)
        super(args)
        @hidden = false
        @new_slice_style = true # switch to new slice style

        # define few of "help strings"
        register_help_string = "bmc register (JSON STRING)"
        get_help_string = "bmc get info|enables|guid|chassis_status (JSON STRING)"
        power_help_string = "bmc power on|off|cycle|reset|status (JSON STRING)"
        lan_help_string = "bmc lan print (JSON STRING)"
        fru_help_string = "bmc fru print (JSON STRING)"
        general_help_string = "bmc [power|get|lan|fru [subcommand_action] (JSON STRING)]"

        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = { :register => "register_bmc",
                            :get => { :info => "run_ipmi_query_cmd",
                                      :enables => "run_ipmi_query_cmd",
                                      :guid => "run_ipmi_query_cmd",
                                      :chassis_status => "run_ipmi_query_cmd",
                                      :all => "query_bmc",
                                      :default => "query_bmc",
                                      :else => :help,
                                      :help => get_help_string},
                            :power => { :on => "change_bmc_power_state",
                                        :off => "change_bmc_power_state",
                                        :cycle => "change_bmc_power_state",
                                        :reset => "change_bmc_power_state",
                                        :status => "run_ipmi_query_cmd",
                                        :default => :help,
                                        :else => :help,
                                        :help => power_help_string},
                            :lan => { :print => "run_ipmi_query_cmd",
                                      :default => :help,
                                      :else => :help,
                                      :help => lan_help_string},
                            :fru => { :print => "run_ipmi_query_cmd",
                                      :default => :help,
                                      :else => :help,
                                      :help => fru_help_string},
                            :default => "query_bmc",
                            :else => "query_bmc_by_uuid",
                            :help => general_help_string}
        @slice_name = "Bmc"
        data = ProjectRazor::Data.new
        config = data.config
        @ipmi_username = config.default_ipmi_username
        @ipmi_password = config.default_ipmi_password
      end

      # Registers BMC NIC
      def register_bmc
        logger.debug "Register bmc called"
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))
            @uuid = @vars_hash['uuid']
            @mac = @vars_hash['mac']
            @ip = @vars_hash['ip']
          else
            #Same vars as above but pulled from CLI arg / Web PATH
            @uuid, @mac, @ip = *@command_array
          end
        end
        unless @uuid || @mac || @ip
          command_name = @prev_args.look
          command_args_array = get_command_array_args
          @uuid, @mac, @ip, @current_power_state = parse_bmc_metadata_args(command_args_array)
        end
        begin
          # if we have the details we need, then insert this bmc into the database (or
          # update the matching bmc object, if one exists)
          if @uuid && @mac && @ip
            logger.debug "bmc: #{@mac} #{@ip}"
            timestamp = Time.now.to_i
            new_bmc = insert_bmc({"@uuid" => @uuid,
                                  "@mac" => @mac,
                                  "@ip" => @ip,
                                  "@current_power_state" => @current_power_state,
                                  "@timestamp" => timestamp})

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

      # Handler for running IPMI-style queries against the underlying bmc node
      # This method is meant to be invoked from the various commands provided by
      # the slice to query the underlying bmc for information
      def run_ipmi_query_cmd
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))

            if @vars_hash['uuid']
              @vars_hash['hw_id'] = @vars_hash['uuid']
            end
            @hw_id = @vars_hash['hw_id']
            @last_state = @vars_hash['last_state']
          else
            #Same vars as above but pulled from CLI arg / Web PATH
            @hw_id, @last_state = *@command_array
          end
        end
        command_query_type = @prev_args.peek(1)
        command_query_string = @prev_args.look
        command_args_array = get_command_array_args
        return
        if @command_query_string == "{}"
          logger.error "Missing Identifier/Filter-Expression"
          slice_error("MissingDetails")
        else
          begin
            details = JSON.parse(@command_query_string)
            if details['@uuid'] != nil
              logger.debug "Running ipmi_query command #{ipmitool_cmd} on bmc: #{details['@uuid']}"
              details['@timestamp'] = Time.now.to_i
              bmc = get_bmc(details)
              command_success, output = bmc.run_ipmi_query_cmd(ipmitool_cmd, @ipmi_username, @ipmi_password)
              # handle the returned values;
              if command_success
                p output
              else
                logger.error output
                slice_error("IpmiCommandFailed", false)
              end
            else
              logger.error "Incomplete Identifier/Filter-Expression"
              slice_error("IncompleteDetails", false)
            end
          rescue StandardError => e
            slice_error(e.message, false)
          end
        end
      end

      # Handler for changing power state of a bmc node to a new state
      # This method is meant to be invoked from the various commands provided by
      # the slice to change the power-state of the node
      def change_bmc_power_state
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))

            if @vars_hash['uuid']
              @vars_hash['hw_id'] = @vars_hash['uuid']
            end
            @hw_id = @vars_hash['hw_id']
            @last_state = @vars_hash['last_state']
          else
            #Same vars as above but pulled from CLI arg / Web PATH
            @hw_id, @last_state = *@command_array
          end
        end
        new_state = @prev_args.look
        command_args_array = get_command_array_args
        return
        if command_query_string == "{}"
          logger.error "Missing Identifier/Filter-Expression"
          slice_error("MissingDetails")
        else
          begin
            details = JSON.parse(@command_query_string)
            if details['@uuid'] != nil
              logger.debug "Changing power-state of bmc: #{details['@uuid']} to #{new_state}"
              details['@timestamp'] = Time.now.to_i
              bmc = get_bmc(details)
              power_state_changed, status_string = bmc.change_power_state(new_state, @ipmi_username, @ipmi_password)
              # handle the returned values; how the returned values should be handled will vary
              # depending on the "new_state" that the node is being transitioned into.  For example,
              # you can only turn on a node that is off (or turn off a node that is on), but it
              # isn't an error to turn on a node that is already on (or turn off a node that is
              # already off) since that operation is, in effect, a no-op.  On the other hand,
              # it is an error to try to power-cycle or reset a node that isn't already on, since
              # these operations don't make any sense on a powered-off node.
              case new_state
                when new_state = "on"
                  if power_state_changed && /Up\/On/.match(status_string)
                    slice_success("Node #{details['@uuid']} now powering on", false)
                  elsif !power_state_changed && /Up\/On/.match(status_string)
                    slice_success("Node #{details['@uuid']} already powered on", false)
                  else
                    logger.error "Could not power on bmc"
                    slice_error("CouldNotPowerOn", false)
                  end
                when new_state = "off"
                  if power_state_changed && /Down\/Off/.match(status_string)
                    slice_success("Node #{details['@uuid']} now powering off", false)
                  elsif !power_state_changed && /Down\/Off/.match(status_string)
                    slice_success("Node #{details['@uuid']} already powered off", false)
                  else
                    logger.error "Could not power off bmc"
                    slice_error("CouldNotPowerOff", false)
                  end
                when new_state = "cycle"
                  if power_state_changed && /Cycle/.match(status_string)
                    slice_success("Node #{details['@uuid']} now power cycling", false)
                  elsif !power_state_changed && /Off/.match(status_string)
                    slice_error("Node #{details['@uuid']} powered off, cannot power cycle", false)
                  else
                    logger.error "Could not power off bmc"
                    slice_error("CouldNotPowerOff", false)
                  end
                when new_state = "reset"
                  if power_state_changed && /Reset/.match(status_string)
                    slice_success("Node #{details['@uuid']} now powering off", false)
                  elsif !power_state_changed && /Off/.match(status_string)
                    slice_error("Node #{details['@uuid']} powered off, cannot reset", false)
                  else
                    logger.error "Could not power off bmc"
                    slice_error("CouldNotPowerOff", false)
                  end
              end
            else
              logger.error "Incomplete Identifier/Filter-Expression"
              slice_error("IncompleteDetails", false)
            end
          rescue StandardError => e
            slice_error(e.message, false)
          end
        end
      end

      # Updates the '@current_power_state' and '@board_serial_number' fields in the bmc_hash
      # using run_ipmi_query calls to the underlying ProjectRazor::PowerControl::Bmc object.
      # The bmc_hash is modified during the call and, as a result, contains the correct current
      # values for these two fields in the bmc_hash when control is returned to the caller
      #
      # @param bmc [ProjectRazor::PowerControl::Bmc]
      # @param bmc_hash [Hash]
      def update_bmc_hash!(bmc, bmc_hash)
        # values to return if the ipmitool command does not succeed
        bmc_hash["@current_power_state"] = "unknown"
        bmc_hash["@board_serial_number"] = ''
        # now, invoke run the ipmitool commands needed to get the current-power-state and
        # board-serial-number for this bmc node
        command_success, power_state = bmc.run_ipmi_query_cmd("power_status", @ipmi_username, @ipmi_password)
        bmc_hash["@current_power_state"] = power_state if command_success
        command_success, fru_hash = bmc.run_ipmi_query_cmd("fru_print", @ipmi_username, @ipmi_password)
        bmc_hash["@board_serial_number"] = fru_hash[:Board_Serial] if command_success
      end

      # Inserts a new Bmc object into the database (or updates a matching Bmc object in the database
      # where the match is determined based on uuid values) using the bmc_hash as input.  There are
      # three possible outcomes from this method:
      #
      #     1. If there is a node who's uuid value matches that found in the '@uuid' field of the
      #        bmc_hash, and if the meta-data contained in that object ('@mac', '@ip', '@current_power_state',
      #        or '@board_serial_number') differ from those found in the bmc_hash, then that object
      #        is updated in the database, and the updated object is returned to the caller
      #     2. If there is no matching object (by uuid), then a new object is created using the bmc_hash
      #        as input, that new object is persisted to the database, and the new object is returned
      #        to the caller
      #     3. If there is a matching object but the meta-data values it contains are the same as those
      #        found in the bmc_hash object, then the matching object is returned to the caller unchanged.
      #
      # @param [Hash] bmc_hash
      # @return [ProjectRazor::PowerControl::Bmc]
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
            # values to use if the ipmitool commands fail for some reason
            bmc.current_power_state = "unknown"
            bmc.board_serial_number = ''
            # now, invoke run the ipmitool commands needed to get the current-power-state and
            # board-serial-number for this bmc node
            command_success, power_state = bmc.run_ipmi_query_cmd("power_status", @ipmi_username, @ipmi_password)
            bmc.current_power_state = power_state if command_success
            command_success, fru_hash = bmc.run_ipmi_query_cmd("fru_print", @ipmi_username, @ipmi_password)
            bmc.board_serial_number = fru_hash[:Board_Serial] if command_success
            bmc.update_self
          end
          bmc
        else
          bmc = ProjectRazor::PowerControl::Bmc.new(bmc_hash)
          begin
            command_success, power_state = bmc.run_ipmi_query_cmd("power_status", @ipmi_username, @ipmi_password)
            bmc.current_power_state = power_state if status_flag
            command_success, fru_hash = bmc.run_ipmi_query_cmd("fru_print", @ipmi_username, @ipmi_password)
            bmc.board_serial_number = fru_hash[:Board_Serial] if status_flag
          rescue => e
            bmc.current_power_state = "unknown"
            bmc.board_serial_number = ''
          end
          @data.persist_object(bmc)
          bmc
        end
      end

      # searches for a Bmc node that matches the '@uuid' value contained in the input bmc_hash
      # argument, then refreshes the current power state in that Bmc object and returns it to
      # the caller
      #
      # @param bmc_hash [Hash]
      # @return [ProjectRazor::PowerControl::Bmc]
      def get_bmc(bmc_hash)
        setup_data
        existing_bmc = @data.fetch_object_by_uuid(:bmc, bmc_hash['@uuid'])
        existing_bmc.refresh_power_state if existing_bmc
        existing_bmc
      end

      # prints out an array of Bmc nodes in a tabular form (using the centralized print_object_array method)
      def query_bmc
        bmc_array = get_object("bmc", :bmc)
        if bmc_array
          bmc_array.each { |bmc|
            bmc.refresh_power_state
          }
        end
        print_object_array get_object("bmc", :bmc), "Bmc Nodes"
      end

      def query_bmc_by_uuid
        setup_data
        @uuid = @command_array.shift unless @uuid
        matching_bmc = @data.fetch_object_by_uuid(:bmc, @uuid)
        if matching_bmc
          bmc_array = [matching_bmc]
          print_object_array bmc_array, "Bmc Nodes"
        else
          slice_error("NoMatchingBMC")
        end
      end

      # return the remainder of the @command_array string as an array of arguments; Note that calling
      # this method will shift all remaining elements out of the @command_array instance variable, so
      # caution should be used when invoking this method
      def get_command_array_args
        command_args_array = []
        while (tmp_str = @command_array.shift)
          command_args_array << tmp_str
        end
        command_args_array
      end

      # used to parse the command-line arguments received as part of a command and return the
      # 'uuid', 'mac', and 'ip' values they might contain (all of those arguments may not be present)
      def parse_bmc_metadata_args(command_args_array)
        uuid = nil
        mac = nil
        ip = nil
        current_power_state = nil
        command_args_array.each { |name_val|
          if (match = /([A-Za-z0-9]+)=(.*)/.match(name_val))
            name = match[1]
            value = match[2]
            case name
              when name = "uuid"
                uuid = value
              when name = "mac"
                mac = value
              when name = "ip"
                ip = value
              when name = "current_power_state"
                current_power_state = value
              else
                logger.warn "Could not parse key-value argument #{name_val}"
            end
          else
            logger.error "Could not parse command line name-value pairs #{command_args_array.inspect}"
            slice_error("CommandParseError")
          end
        }
        return [uuid, mac, ip, current_power_state]
      end

    end
  end
end
