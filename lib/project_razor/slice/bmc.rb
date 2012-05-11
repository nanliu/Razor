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

      # defines the default set of field names that can be used to filter the effects
      # of BMC Slice sub-commands
      DEFAULT_FIELDS_ARRAY = %W[uuid, mac, ip, current_power_state, board_serial_number]

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
                                      :else => "query_bmc_by_uuid",
                                      :help => get_help_string},
                            :power => { :on => "change_bmc_power_state",
                                        :off => "change_bmc_power_state",
                                        :cycle => "change_bmc_power_state",
                                        :reset => "change_bmc_power_state",
                                        :status => "run_ipmi_query_cmd",
                                        :default => :help,
                                        :else => :print,
                                        :help => power_help_string},
                            :lan => { :print => "run_ipmi_query_cmd",
                                      :default => :help,
                                      :else => :print,
                                      :help => lan_help_string},
                            :fru => { :print => "run_ipmi_query_cmd",
                                      :default => :help,
                                      :else => :print,
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
          @current_power_state = nil
          @board_serial_number = nil
          @uuid, @mac, @ip = parse_bmc_metadata_args(command_args_array, ["uuid", "mac", "ip"])
        end
        begin
          # if we have the details we need, then insert this bmc into the database (or
          # update the matching bmc object, if one exists, otherwise, raise an exception)
          raise ProjectRazor::Error::Slice::MissingArgument, "cannot register BMC without specifying the UUID, MAC, and IP" unless @uuid && @mac && @ip
          logger.debug "bmc: #{@mac} #{@ip}"
          timestamp = Time.now.to_i
          bmc_hash = {"@uuid" => @uuid,
                      "@mac" => @mac,
                      "@ip" => @ip,
                      "@current_power_state" => @current_power_state,
                      "@board_serial_number" => @board_serial_number,
                      "@timestamp" => timestamp}
          new_bmc = insert_bmc(bmc_hash)
          raise ProjectRazor::Error::Slice::CouldNotRegisterBmc, "failed to refresh BMC state" unless new_bmc
          update_success = new_bmc.refresh_self
          raise ProjectRazor::Error::Slice::InternalError, "failed to refresh BMC state" unless update_success
          slice_success(new_bmc.to_hash)
        rescue ProjectRazor::Error::Slice::Generic => e
          raise e
        rescue StandardError => e
          raise ProjectRazor::Error::Slice::InternalError, "error occurred while inserting BMC " + e.message
        end
      end

      # Handler for running IPMI-style queries against the underlying bmc node
      # This method is meant to be invoked from the various commands provided by
      # the slice to query the underlying bmc for information
      def run_ipmi_query_cmd
        ipmitool_cmd = ""
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))
            @uuid = @vars_hash['uuid']
          else
            #Same vars as above but pulled from CLI arg / Web PATH
            sub_command = @prev_args.peek(1)
            sub_command_action = @prev_args.look
            ipmitool_cmd = map_to_ipmitool_cmd(sub_command, sub_command_action)
            lcl_command_array = *@command_array
            @uuid = lcl_command_array[0]
          end
        end
        unless @uuid || @mac || @ip
          sub_command = @prev_args.peek(1)      # will be a string like "get", "lan", "power", or "fru"
          sub_command_action = @prev_args.look
          ipmitool_cmd = map_to_ipmitool_cmd(sub_command, sub_command_action)
          command_args_array = get_command_array_args
          @uuid = command_args_array.shift
        end
        raise ProjectRazor::Error::Slice::MissingArgument, "uuid value not specified" unless @uuid
        begin
          bmc = get_bmc(@uuid)
          raise ProjectRazor::Error::Slice::InvalidUUID, "no matching BMC (with a uuid value of '#{@uuid}') found" unless bmc
          command_success, output = bmc.run_ipmi_query_cmd(ipmitool_cmd, @ipmi_username, @ipmi_password)
          # handle the returned values;
          # throw an error if the command failed to execute properly
          raise ProjectRazor::Error::Slice::InvalidCommand,
                "ipmi query command '#{ipmitool_cmd}' failed" unless command_success
        rescue ProjectRazor::Error::Slice::Generic => e
          raise e
        rescue StandardError => e
          raise ProjectRazor::Error::Slice::InternalError,
                "error occurred while executing ipmi query command #{ipmitool_cmd} -> #{e.message}"
        end
      end

      # map the combination of a sub_command and an action on that sub_command
      # into an ipmitool_cmd.  Valid sub_command/action combinations (and the
      # ipmitool_cmd they map into) are as follows:
      #
      # lan or fru -> print
      # power, status => power_status
      # get, info => bmc_info
      # get, enables => bmc_getenables
      # get, guid => bmc_guid
      # get, chassis_status => chassis_status
      # lan, print => lan_print
      # fru, print => fru_print
      def map_to_ipmitool_cmd(sub_command, sub_command_action)
        case "#{sub_command}, #{sub_command_action}"
          when "power, status"
            return "power_status"
          when "get, info"
            return "bmc_info"
          when "get, enables"
            return "bmc_getenables"
          when "get, guid"
            return "bmc_guid"
          when "get, chassis_status"
            return "chassis_status"
          when "lan, print"
            return "lan_print"
          when "fru, print"
            return "fru_print"
          else
            raise ProjectRazor::Error::Slice::SliceCommandParsingFailed,
                  "the BMC sub-command '#{sub_command} #{sub_command_action}' is not recognized"
        end
      end

      # Handler for changing power state of a bmc node to a new state
      # This method is meant to be invoked from the various commands provided by
      # the slice to change the power-state of the node
      def change_bmc_power_state
        new_state = ""
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))
            @uuid = @vars_hash['uuid']
          else
            #Same vars as above but pulled from CLI arg / Web PATH
            new_state = @prev_args.look
            lcl_command_array = *@command_array
            @uuid = lcl_command_array[0]
          end
        end
        unless @uuid || @mac || @ip
          new_state = @prev_args.look
          command_args_array = get_command_array_args
          @uuid = command_args_array.shift
        end
        raise ProjectRazor::Error::Slice::InvalidCommand, "missing details for command to change power state" unless
            new_state && new_state.length > 0
        begin
          raise ProjectRazor::Error::Slice::MissingArgument, "missing the uuid value for command to change power state" unless @uuid
          logger.debug "Changing power-state of bmc: #{@uuid} to #{new_state}"
          bmc = get_bmc(@uuid)
          power_state_changed, status_string = bmc.change_power_state(new_state, @ipmi_username, @ipmi_password)
          # handle the returned values; how the returned values should be handled will vary
          # depending on the "new_state" that the node is being transitioned into.  For example,
          # you can only turn on a node that is off (or turn off a node that is on), but it
          # isn't an error to turn on a node that is already on (or turn off a node that is
          # already off) since that operation is, in effect, a no-op.  On the other hand,
          # it is an error to try to power-cycle or reset a node that isn't already on, since
          # these operations don't make any sense on a powered-off node.
          result_string = ""
          case new_state
            when new_state = "on"
              if power_state_changed && /Up\/On/.match(status_string)
                # success condition
                result_string = "node #{@uuid} now powering on"
              elsif !power_state_changed && /Up\/On/.match(status_string)
                # success condition
                result_string = "node #{@uuid} already powered on"
              else
                # error condition
                result_string = "attempt to power on Node #{@uuid} failed"
              end
              raise ProjectRazor::Error::Slice::CommandFailed, result_string unless
                  power_state_changed && /Up\/On/.match(status_string) ||
                      !power_state_changed && /Up\/On/.match(status_string)
            when new_state = "off"
              if power_state_changed && /Down\/Off/.match(status_string)
                # success condition
                result_string = "node #{@uuid} now powering off"
              elsif !power_state_changed && /Down\/Off/.match(status_string)
                # success condition
                result_string = "node #{@uuid} already powered off"
              else
                # error condition
                result_string = "attempt to power off Node #{@uuid} failed"
              end
              raise ProjectRazor::Error::Slice::CommandFailed, result_string unless
                  power_state_changed && /Down\/Off/.match(status_string) ||
                      !power_state_changed && /Down\/Off/.match(status_string)
            when new_state = "cycle"
              if power_state_changed && /Cycle/.match(status_string)
                # success condition
                result_string = "node #{@uuid} now power cycling"
              elsif !power_state_changed && /Off/.match(status_string)
                # error condition
                result_string = "node #{@uuid} powered off, cannot power cycle"
              else
                # error condition
                result_string = "attempt to power cycle Node #{@uuid} failed"
              end
              raise ProjectRazor::Error::Slice::CommandFailed, result_string unless
                  power_state_changed && /Cycle/.match(status_string)
            when new_state = "reset"
              if power_state_changed && /Reset/.match(status_string)
                # success condition
                result_string = "node #{@uuid} now powering off"
              elsif !power_state_changed && /Off/.match(status_string)
                # error condition
                result_string = "node #{@uuid} powered off, cannot reset"
              else
                # error condition
                result_string = "attempt to reset Node #{@uuid} failed"
              end
              raise ProjectRazor::Error::Slice::CommandFailed, result_string unless
                  power_state_changed && /Reset/.match(status_string)
          end
          slice_success(result_string)
        rescue ProjectRazor::Error::Slice::Generic => e
          raise e
        rescue StandardError => e
          raise ProjectRazor::Error::Slice::InternalError, "an error occurred while changing power state -> #{e.message}"
        end
      end

      # Updates the '@current_power_state' and '@board_serial_number' fields in the bmc_hash
      # using run_ipmi_query calls to the underlying ProjectRazor::PowerControl::Bmc object.
      # The bmc_hash is modified during the call and, as a result, contains the correct current
      # values for these two fields in the bmc_hash when control is returned to the caller
      #
      # @param [ProjectRazor::PowerControl::Bmc] bmc
      # @param [Hash] bmc_hash
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
        # if we have a matching BMC already in the database with that name
        if bmc != nil
          # and if the details in the bmc_hash are different from the details
          # for the BMC in object in the database, then update the database object
          # to match the details in the bmc_hash
          if (bmc.mac != bmc_hash['@mac'] || bmc.ip != bmc_hash['@ip'] ||
              bmc.current_power_state != bmc_hash['@current_power_state'] ||
              bmc.board_serial_number != bmc_hash['@board_serial_number'])
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
        else
          # else, if there is no matching BMC object in the database, add a new object
          # using the contents of the bmc_hash as input (and setting the current_power_state
          # and board_serial number to values gathered usign the corresponding IPMI queries)
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
        end
        bmc
      end

      # searches for a Bmc node that matches the '@uuid' value contained in the input bmc_hash
      # argument, then refreshes the current power state in that Bmc object and returns it to
      # the caller
      #
      # @param [String] uuid
      # @return [ProjectRazor::PowerControl::Bmc]
      def get_bmc(uuid)
        setup_data
        existing_bmc = @data.fetch_object_by_uuid(:bmc, uuid)
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
        raise ProjectRazor::Error::Slice::InvalidUUID, "no matching BMC (with a uuid value of '#{@uuid}') found" unless matching_bmc
        bmc_array = [matching_bmc]
        print_object_array bmc_array, "Bmc Nodes"
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
      # @param [Object] command_args_array  The array of arguments to parse
      # @param [Object] return_fields  An array containing a list of field names to return (in the order
      # in which they should be returned).  Any fields not in this list will be skipped
      def parse_bmc_metadata_args(command_args_array, return_fields)
        # if no return fields are requested, then return nothing (an empty array)
        return [] if !return_fields || return_fields.size == 0
        # initialize the return values (to nil) by pre-allocating an appropriately size array
        return_vals = Array.new(return_fields.size)
        # parse the command_args_array as "name=value" pairs
        command_args_array.each { |name_val|
          match = /([A-Za-z0-9]+)=(.*)/.match(name_val)
          raise ProjectRazor::Error::Slice::SliceCommandParsingFailed,
                "could not parse command line argument #{name_val}; expected 'name=value' format" unless match
          name = match[1]
          value = match[2]
          idx = return_fields.index(name)
          raise ProjectRazor::Error::Slice::SliceCommandParsingFailed,
                "unrecognized field with name #{name}; valid values are #{return_fields.inspect}" unless idx
          return_vals[idx] = value
        }
        return return_vals
      end

    end
  end
end
