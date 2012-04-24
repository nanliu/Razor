# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"

# Root namespace for policy objects
# used to find them in object space for type checking
Policy_PREFIX = "ProjectRazor::Policy::"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice

    # ProjectRazor Slice Policy (NEW))
    # Used for policy management
    # @author Nicholas Weaver
    class Newpolicy < ProjectRazor::Slice::Base

      # Initializes ProjectRazor::Slice::Policy including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        @new_slice_style = true # switch to new slice style
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:add => "add_policy",
                           :get => {["all", '{}', /^{.*}$/, nil] => "get_policy_all",
                                    [/type/,"t"] => "get_policy_types",
                                    :default => "get_policy_all",
                                    :else => "get_policy_with_uuid",
                                    :help => "razor policy get all|type|(uuid)"},
                           :type => "get_policy_types",
                           [/type/,"t"] => "get_policy_types",
                           :default => "get_policy_all",
                           :remove => "remove_policy",
                           :else => :get,
                           :help => "razor policy add|remove|get [all|type|(uuid)]"}
        @slice_name = "Newpolicy"
      end

      # Returns all policy instances
      def get_policy_all
        # Get all policy instances and print/return
        @command_array.unshift(@last_arg) unless @last_arg == 'default'
        print_object_array get_object("policy_instances", :policy), "policy Instances"
      end

      # Returns the policy types available
      def get_policy_types
        # We use the common method in Utility to fetch object types by providing Namespace prefix
        print_object_array get_types_as_object_types(POLICY_PREFIX), "\nPossible policy Types:"
      end

      def get_policy_with_uuid
        @command_help_text = "razor policy get all|type|(uuid)"
        @arg = @command_array.shift
        policy = get_object("policy instances", :policy, @arg)
        case policy
          when nil
            slice_error("Cannot Find Policy with UUID: [#@arg]")
          else
            print_object_array [policy]
        end
      end

      def add_policy
        # Set the command we have selected
        @command =:add
        # Set out help text
        @command_help_text = "razor policy " + "(policy type) (Name) (Description) [(server hostname),{server hostname}]".yellow
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))
            # Policy type (must match a proper policy type)
            @type = @vars_hash['type']
            # Policy Name (user defined)
            @name = @vars_hash['name']
            # Policy User Description (user defined)
            @user_description = @vars_hash['description']
            # Policy Servers (user defined comma-delimited list of servers, must be at list one)
            @servers = @vars_hash['servers']
          else
            #Same vars as above but pulled from CLI arg / Web PATH
            @type, @name, @user_description, @servers = *@command_array
          end
        end
        @type, @name, @user_description, @servers = *@command_array unless @type || @name || @user_description || @servers
        # Validate our args are here
        return slice_error("Must Provide Policy Type [type]") unless validate_arg(@type)
        return slice_error("Must Provide Policy Name [name]") unless validate_arg(@name)
        return slice_error("Must Provide Policy Description [description]") unless validate_arg(@user_description)
        return slice_error("Must Provide Policy Servers [servers]") unless validate_arg(@servers)
        # Convert our servers var to an Array if it is not one already
        @servers = @servers.split(",") unless @servers.respond_to?(:each)
        return slice_error("Must Provide At Least One Policy Server [servers]") unless @servers.count > 0
        # We use the [is_valid_type?] method from Utility to validate our type vs our object namespace prefix
        unless is_valid_type?(SYSTEM_PREFIX, @type)
          # Return error
          slice_error("InvalidPolicyType")
          # Also print possible types if not a REST call
          get_policy_types unless @web_command
          return
        end
        new_policy = new_object_from_type_name(SYSTEM_PREFIX, @type)
        new_policy.name = @name
        new_policy.user_description = @user_description
        new_policy.servers = @servers
        setup_data
        @data.persist_object(new_policy)
        if new_policy
          @command_array.unshift(new_policy.uuid)
          get_policy_with_uuid
        else
          slice_error("CouldNotSavePolicy")
        end
      end

      def remove_policy
        @command_help_text = "razor policy remove all|(uuid)"
        # Grab the arg
        @arg = @command_array.shift
        case @arg
          when "all" # if [all] we remove all instances
            setup_data # setup the data object
            @data.delete_all_objects(:policy) # remove all policy instances
            slice_success("All Policy deleted") # return success
          when nil
            slice_error("Command Error") # return error for no arg
          else
            policy = get_object("policy instances", :policy, @arg) # attempt to find policy with uuid
            case policy
              when nil
                slice_error("Cannot Find Policy with UUID: [#@arg]") # error when it is invalid
              else
                setup_data
                @data.delete_object_by_uuid(:policy, @arg)
                slice_success("Policy deleted")
            end
        end
      end
    end
  end
end

