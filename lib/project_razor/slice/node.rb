# Root ProjectRazor namespace
module ProjectRazor
  module Slice
    # ProjectRazor Slice Node (NEW)
    # Used for policy management
    class Node < ProjectRazor::Slice::Base
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden          = false
        @new_slice_style = true
        @slice_name = "Node"
        @engine = ProjectRazor::Engine.instance
        @slice_commands = {
            :get => "get_node",
            ["register", /^[Rr]$/] => "register_node",
            ["checkin", /^[Cc]$/] => "checkin_node",
            :default => :get,
            :else => :get,
            ["--help", "-h"] => "node_help"
        }
      end

      def node_help
        puts "Node Slice: used to view the current list of nodes; also used by the Microkernel".red
        puts "    for the node registration and checkin processes.".red
        puts "Node Commands:".yellow
        puts "\trazor node [get] [--all]              " + "Display list of available nodes".yellow
        puts "\trazor node [get] (UUID)               " + "Display details for a node".yellow
        puts "\trazor node [get] (UUID) --attributes  " + "Display detailed attributes for a node".yellow
        puts "\trazor node [get] (UUID) --hardware    " + "Display hardware ID values for a node".yellow
        puts "\trazor node checkin (options...)       " + "Used for node checkin".yellow
        puts "\trazor node register (options...)      " + "Used for node registration".yellow
        puts "\trazor node --help                     " + "Display this screen".yellow
      end

      def get_node
        @command = :get_node
        @command_help_text << "Description: Gets the Properties Associated with one or more Nodes\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :get)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        node_uuid, options = parse_and_validate_options(option_items, "razor node get [UUID] [option]", :require_all)
        if !@web_command
          node_uuid = @command_array.shift
        end
        includes_uuid = true if node_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        if options[:attrib]
          # get the list of attributes for the chosen node
          get_node_attributes(node_uuid)
        elsif options[:hw_id]
          # get the hardware ids for the chosen node
          get_node_hardware_ids(node_uuid)
        elsif includes_uuid
          # get the details for a specific node
          get_node_with_uuid(node_uuid)
        else
          # get a summary view of all nodes; will end up here
          # if the option chosen is the :all option (or if nothing but the
          # 'get' subcommand was specified as this is the default action)
          get_nodes_all
        end
      end

      def get_nodes_all
        # Get all node instances and print/return
        #@command = :get_nodes_all
        #@command_array.unshift(@last_arg) unless @last_arg == 'default'
        print_object_array get_object("nodes", :node), "Discovered Nodes", :style => :table
      end

      def get_node_with_uuid(node_uuid)
        #@command = :get_node_with_uuid
        #@command_help_text = "razor node [get] (uuid)"
        node = get_object("node_with_uuid", :node, node_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Node with UUID: [#{node_uuid}]" unless node
        print_object_array [node]
      end

      def get_node_attributes(node_uuid)
        #@command = :get_node_attributes
        #@command_help_text = "razor node [get] attributes[a] (uuid)"
        node = get_object("node_with_uuid", :node, node_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Node with UUID: [#{node_uuid}]" unless node
        if @web_command
          print_object_array [Hash[node.attributes_hash.sort]]
        else
          print_object_array node.print_attributes_hash, "Node Attributes:"
        end
      end

      def get_node_hardware_ids(node_uuid)
        #@command = :get_node_attributes
        #@command_help_text = "razor node [get] attributes[a] (uuid)"
        node = get_object("node_with_uuid", :node, node_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Node with UUID: [#{node_uuid}]" unless node
        if @web_command
          print_object_array [{"hw_id" => node.hw_id}]
        else
          print_object_array node.print_hardware_ids, "Node Hardware ID's:"
        end
      end

      def register_node
        @command = :register_node
        @command_name = "register_node"
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))
            @vars_hash['hw_id'] = @vars_hash['uuid'] if @vars_hash['uuid']
            @hw_id = @vars_hash['hw_id']
            @last_state = @vars_hash['last_state']
            @attributes_hash = @vars_hash['attributes_hash']
          end
        end
        @hw_id, @last_state, @attributes_hash = *@command_array unless @hw_id || @last_state || @attributes_hash
        # Validate our args are here
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Hardware IDs[hw_id]" unless validate_arg(@hw_id)
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Last State[last_state]" unless validate_arg(@last_state)
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Attributes Hash[attributes_hash]" unless @attributes_hash.is_a? Hash and @attributes_hash.size > 0
        @hw_id = @hw_id.split("_") if @hw_id.is_a? String
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide At Least One Hardware ID [hw_id]" unless @hw_id.count > 0
        @engine = ProjectRazor::Engine.instance
        @new_node = @engine.lookup_node_by_hw_id(:hw_id => @hw_id)
        if @new_node
          @new_node.hw_id = @new_node.hw_id | @hw_id
        else
          shell_node = ProjectRazor::Node.new({})
          shell_node.hw_id = @hw_id
          @new_node = @engine.register_new_node_with_hw_id(shell_node)
          raise ProjectRazor::Error::Slice::CouldNotRegisterNode, "Could not register new node" unless @new_node
        end
        @new_node.timestamp = Time.now.to_i
        @new_node.attributes_hash = @attributes_hash
        @new_node.last_state = @last_state
        raise ProjectRazor::Error::Slice::CouldNotRegisterNode, "Could not register node" unless @new_node.update_self
        slice_success(@new_node.to_hash, :mk_response => true)
      end

      def checkin_node
        @command = :checkin_node
        @command_name = "checkin_node"
        # If a REST call we need to populate the values from the provided JSON string
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash = sanitize_hash(JSON.parse(json_string))
            @vars_hash['hw_id'] = @vars_hash['uuid'] if @vars_hash['uuid']
            @hw_id = @vars_hash['hw_id']
            @last_state = @vars_hash['last_state']
            @first_checkin = @vars_hash['first_checkin']
          end
        end
        @hw_id, @last_state, @first_checkin = *@command_array unless @hw_id || @last_state || @first_checkin
        # Validate our args are here
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Hardware IDs[hw_id]" unless validate_arg(@hw_id)
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Last State[last_state]" unless validate_arg(@last_state)
        @hw_id = @hw_id.split("_") unless @hw_id.is_a? Array

        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide At Least One Hardware ID [hw_id]" unless @hw_id.count > 0
        # if it's not the first node, check to see if the node exists
        unless @first_checkin
          @new_node = @engine.lookup_node_by_hw_id(:hw_id => @hw_id)
          if @new_node
            # if a node with this hardware id exists, simply acknowledge the checkin request
            command = @engine.mk_checkin(@new_node.uuid, @last_state)
            return slice_success(command, :mk_response => true)
          end
        end
        # otherwise, if we get this far, return a command telling the Microkernel to register
        # (either because no matching node already exists or because it's the first checkin
        # by the Microkernel)
        slice_success(@engine.mk_command(:register,{}), :mk_response => true)
      end
    end
  end
end


