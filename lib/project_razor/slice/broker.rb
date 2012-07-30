require "json"

# Root namespace for broker objects
# used to find them in object space for plugin checking
BROKER_PREFIX = "ProjectRazor::BrokerPlugin::"

# Root ProjectRazor namespace
module ProjectRazor
  module Slice

    # ProjectRazor Slice Broker
    # Used for broker management
    class Broker < ProjectRazor::Slice::Base

      # Initializes ProjectRazor::Slice::Broker including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden          = false
        @new_slice_style = true # switch to new slice style
                                # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands  = {
            :add => "add_broker",
            :update => "update_broker",
            :get => "get_broker",
            :plugin => "get_broker_plugins",
            [/plugin/, "t"] => "get_broker_plugins",
            :remove => "remove_broker",
            :default => :get,
            :else => :get,
            ["--help", "-h"] => "broker_help"
        }
        @slice_name      = "Broker"
      end

      def broker_help
        puts "Broker Slice: used to add, view, update, and remove Broker Targets.".red
        puts "Broker Commands:".yellow
        puts "\trazor broker [get] [--all]            " + "View all broker targets".yellow
        puts "\trazor broker [get] (UUID)             " + "View specific broker target".yellow
        puts "\trazor broker add (UUID) (OPTIONS)     " + "View specific broker target".yellow
        puts "\trazor broker update (UUID) (OPTIONS)  " + "View specific broker target".yellow
        puts "\trazor broker remove (UUID)|(--all)    " + "Remove existing (or all) broker target(s)".yellow
        puts "\trazor broker --help                   " + "Display this screen".yellow
      end

      def get_broker
        @command = :get_broker
        @command_help_text << "Description: Gets the properties associated with one or more Broker Targets\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :get)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        broker_uuid, options =
            parse_and_validate_options(option_items,
                                       "razor broker get [UUID]|[--all]|[--plugin][--template]",
                                       :require_all)
        if !@web_command
          broker_uuid = @command_array.shift
        end
        includes_uuid = true if broker_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        if options[:plugin] || options[:template]
          # get the list of attributes for the chosen node
          get_broker_plugins
        elsif includes_uuid
          # get the details for a specific node
          get_broker_with_uuid(broker_uuid)
        else
          # get a summary view of all nodes; will end up here
          # if the option chosen is the :all option (or if nothing but the
          # 'get' subcommand was specified as this is the default action)
          get_broker_all
        end
      end

      def add_broker
        @command = :add_broker
        @command_help_text << "Description: Used to add a new Broker Target to Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "razor broker add OPTIONS", :require_all)
        includes_uuid = true if tmp
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        plugin = options[:plugin]
        name = options[:name]
        description = options[:description]
        servers = options[:servers]
        # check the values that were passed in
        servers = servers.flatten if servers.is_a? Array
        servers = servers.split(",") if servers.is_a? String
        raise ProjectRazor::Error::Slice::MissingArgument, "broker server [server_hostname(,server_hostname)]" unless servers.count > 0
        raise ProjectRazor::Error::Slice::InvalidPlugin, "Invalid broker plugin [#{plugin}]" unless is_valid_template?(BROKER_PREFIX, plugin)
        # use the arguments passed in (above) to create a new broker
        broker                  = new_object_from_template_name(BROKER_PREFIX, plugin)
        broker.name             = name
        broker.user_description = description
        broker.servers          = servers
        broker.is_template      = false
        # persist that broker, and print the result (or raise an error if cannot persist it)
        setup_data
        get_data.persist_object(broker)
        broker ? print_object_array([broker], "", :success_type => :created) : raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Broker Target")
      end

      def update_broker
        @command = :update_broker
        @command_help_text << "Description: Used to update an existing Broker Target\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        broker_uuid, options = parse_and_validate_options(option_items, "razor broker update UUID (OPTIONS)", :require_one)
        if !@web_command
          broker_uuid = @command_array.shift
        end
        includes_uuid = true if broker_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        plugin = options[:plugin]
        name = options[:name]
        description = options[:description]
        servers = options[:servers]
        # check the values that were passed in
        if servers
          servers = servers.split(",") if servers.is_a? String
          raise ProjectRazor::Error::Slice::MissingArgument, "Broker Server [server_hostname(,server_hostname)]" unless servers.count > 0
        end
        broker = get_object("broker_with_uuid", :broker, broker_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Broker Target with UUID: [#{broker_uuid}]" unless broker
        broker.name             = name if name
        broker.user_description = description if description
        broker.servers          = servers if servers
        broker.is_template      = false
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Broker Target [#{broker.uuid}]" unless broker.update_self
        print_object_array [broker], "", :success_type => :updated
      end

      def remove_broker
        @command = :remove_active_model
        @command_help_text << "Description: Remove one (or all) Active Models from Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :remove)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        broker_uuid, options = parse_and_validate_options(option_items, "razor active_model remove (UUID)|(--all)", :require_all)
        if !@web_command
          broker_uuid = @command_array.shift
        end
        includes_uuid = true if broker_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        # selected_option = options.select { |k, v| v }.keys[0].to_s
        if options[:all]
          # remove all Active Models from the system
          remove_broker_all
        elsif includes_uuid
          # remove a specific Active Model (by UUID); this is the default
          # action if no options are specified (the only option currently for
          # this subcommand is the '--all' option)
          remove_broker_by_uuid(broker_uuid)
        else
          # if get to here, no UUID was specified and the '--all' option was
          # no included, so raise an error and exit
          raise ProjectRazor::Error::Slice::MissingArgument, "Must provide a UUID for the broker to remove (or select the '--all' option)"
        end
      end

      # Returns all broker instances
      def get_broker_all
        print_object_array get_object("broker_instances", :broker), "Broker Targets:"
      end

      # Returns the broker plugins available
      def get_broker_plugins
        # We use the common method in Utility to fetch object plugins by providing Namespace prefix
        print_object_array get_child_templates(ProjectRazor::BrokerPlugin), "\nAvailable Broker Plugins:"
      end

      def get_broker_with_uuid(broker_uuid)
        broker             = get_object("broker instances", :broker, broker_uuid)
        raise ProjectRazor::Error::Slice::NotFound, "Broker Target UUID: [#@arg]" unless broker
        print_object_array [broker]
      end

      def remove_broker_all
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Brokers" unless get_data.delete_all_objects(:broker)
        slice_success("All brokers removed", :success_type => :removed)
      end

      def remove_broker_by_uuid(broker_uuid)
        broker = get_object("broker_with_uuid", :broker, broker_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find broker with UUID: [#{broker_uuid}]" unless broker
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove broker [#{broker.uuid}]" unless get_data.delete_object(broker)
        slice_success("Active broker [#{broker.uuid}] removed", :success_type => :removed)
      end
    end
  end
end
