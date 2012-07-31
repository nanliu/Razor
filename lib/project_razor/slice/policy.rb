require "json"

# Root namespace for policy objects
# used to find them in object space for type checking
POLICY_PREFIX = "ProjectRazor::PolicyTemplate::"

# Root ProjectRazor namespace
module ProjectRazor
  module Slice

    # ProjectRazor Slice Policy (NEW))
    # Used for policy management
    class Policy < ProjectRazor::Slice::Base

      # Initializes ProjectRazor::Slice::Policy including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden          = false
        @new_slice_style = true # switch to new slice style
                                # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands  = { :add => "add_policy",
                             :update => "update_policy",
                             :move => "move_policy",
                             :get => "get_policy",
                             :callback => "get_callback",
                             :remove  => "remove_policy",
                             :default => :get,
                             :else => :get,
                             ["help","--help","-h"] => "policy_help" }
        @slice_name      = "Policy"
        @policies        = ProjectRazor::Policies.instance
      end

      def policy_help
        puts "Policy Slice:".red
        puts "Used to view, create, update, and remove policies.".red
        puts "Policy commands:".yellow
        puts "\trazor policy [get] [--all]                    " + "View all policies".yellow
        puts "\trazor policy [get] (UUID)                     " + "View a specific policy".yellow
        puts "\trazor policy [get] --templates                " + "View available policy templates".yellow
        puts "\trazor policy add (options...)                 " + "Create a new policy".yellow
        puts "\trazor policy update (UUID) (options...)       " + "Update an existing policy".yellow
        puts "\trazor policy move (UUID) (--higher|--lower)   " + "Move an existing policy up/down in list".yellow
        puts "\trazor policy remove (UUID)|--all              " + "Remove an existing policy(s)".yellow
        puts "\trazor policy --help|-h                        " + "Display this screen".yellow
      end

      def get_policy
        @command = :get_policy
        @command_help_text << "Description: Gets the properties associated with one or more Policies\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :get)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        policy_uuid, options =
            parse_and_validate_options(option_items,
                                       "razor policy get [UUID]|[--all]|[--possible-models][--templates]|[--broker-targets]",
                                       :require_all)
        if !@web_command
          policy_uuid = @command_array.shift
        end
        includes_uuid = true if policy_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        if options[:templates] || options[:types]
          # get the list of policy templates
          get_policy_templates
        elsif options[:possible_models] || options[:model_configs]
          # get the list of possible models available in the system
          get_possible_models
        elsif options[:broker_targets]
          # get the list of broker targets available in the system
          get_broker_targets
        elsif includes_uuid
          # get the details for a specific policy
          get_policy_with_uuid(broker_uuid)
        else
          # get a summary view of all policies; will end up here
          # if the option chosen is the :all option (or if nothing but the
          # 'get' subcommand was specified as this is the default action)
          get_all_policies
        end
      end

      def add_policy
        @command = :add_policy
        @command_help_text << "Description: Used to add a new Policy to Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "razor policy add (options...)", :require_all)
        includes_uuid = true if tmp
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        # check the values that were passed in
        policy = new_object_from_template_name(POLICY_PREFIX, options[:template])
        raise ProjectRazor::Error::Slice::InvalidPolicyTemplate, "Policy Template is not valid [#{options[:template]}]" unless policy
        setup_data
        model = get_object("model_by_uuid", :model, options[:model_uuid])
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Model UUID [#{options[:model_uuid]}]" unless model
        raise ProjectRazor::Error::Slice::InvalidModel, "Invalid Model Type [#{model.template}] != [#{policy.template}]" unless policy.template == model.template
        broker = get_object("model_by_uuid", :broker, options[:broker_uuid])
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Broker UUID [#{options[:broker_uuid]}]" unless broker || options[:broker_uuid] == "none"
        options[:tags] = options[:tags].split(",") unless options[:tags].class.to_s == "Array"
        raise ProjectRazor::Error::Slice::MissingTags, "Must provide at least one tag [tags]" unless options[:tags].count > 0
        raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be a valid integer" unless options[:maximum].to_i.to_s == options[:maximum]
        raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be > 0" unless options[:maximum].to_i >= 0
        # Flesh out the policy
        policy.label         = options[:label]
        policy.model         = model
        policy.broker        = broker
        policy.tags          = options[:tags]
        policy.enabled       = options[:enabled]
        policy.is_template   = false
        policy.maximum_count = options[:maximum]
        # Add policy
        policy_rules         = ProjectRazor::Policies.instance
        policy_rules.add(policy) ? print_object_array([policy], "Policy created", :success_type => :created) :
            raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Policy")
      end

      def update_policy
        @command = :update_policy
        @command_help_text << "Description: Used to update an existing Policy\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        policy_uuid, options = parse_and_validate_options(option_items, "razor policy update UUID (options...)", :require_one)
        if !@web_command
          policy_uuid = @command_array.shift
        end
        includes_uuid = true if policy_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        # check the values that were passed in
        if options[:tags]
          options[:tags] = options[:tags].split(",") if options[:tags].is_a? String
          raise ProjectRazor::Error::Slice::MissingArgument, "Policy Tags [tag(,tag)]" unless options[:tags].count > 0
        end
        if options[:model_uuid]
          model = get_object("model_by_uuid", :model, options[:model_uuid])
          raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Model UUID [#{options[:model_uuid]}]" unless model
          raise ProjectRazor::Error::Slice::InvalidModel, "Invalid Model Type [#{model.label}]" unless policy.template == model.template
        end
        if options[:broker_uuid]
          broker = get_object("model_by_uuid", :broker, options[:broker_uuid])
          raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Broker UUID [#{options[:broker_uuid]}]" unless broker || options[:broker_uuid] == "none"
        end
        raise ProjectRazor::Error::Slice::MissingArgument, "Cannot use --enable and --disable at the same time." if options[:enable] && options[:disable]
        raise ProjectRazor::Error::Slice::MissingArgument, "Cannot use --move-priority-higher and --move-priority-lower at the same time." if options[:movehigher] && options[:movelower]
        if options[:maximum]
          raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be a valid integer" unless options[:maximum].to_i.to_s == options[:maximum]
          raise ProjectRazor::Error::Slice::InvalidMaximumCount, "Policy maximum count must be > 0" unless options[:maximum].to_i >= 0
        end
        # Update object properties
        policy.label = options[:label] if options[:label]
        policy.model = model if model
        policy.broker = broker if broker
        policy.tags = options[:tags] if options[:tags]
        policy.enabled = true if options[:enable]
        policy.enabled = false if options[:disable]
        policy.maximum_count = options[:maximum] if options[:maximum]
        policy_rules = ProjectRazor::Policies.instance
        policy_rules.move_policy_up(policy.uuid) if options[:movehigher]
        policy_rules.move_policy_down(policy.uuid) if options[:movelower]
        # Update object
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Broker Target [#{broker.uuid}]" unless policy.update_self
        print_object_array [policy], "", :success_type => :updated
      end

      def remove_policy
        @command = :remove_policy
        @command_help_text << "Description: Remove one Policy (or all Policies) from Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :remove)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        policy_uuid, options = parse_and_validate_options(option_items, "razor policy remove (UUID)|(--all)", :require_all)
        if !@web_command
          policy_uuid = @command_array.shift
        end
        includes_uuid = true if policy_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        # selected_option = options.select { |k, v| v }.keys[0].to_s
        if options[:all]
          # remove all Policies from the system
          remove_all_policies
        elsif includes_uuid
          # remove a specific Policy (by UUID)
          remove_policy_with_uuid(broker_uuid)
        else
          # if get to here, no UUID was specified and the '--all' option was
          # no included, so raise an error and exit
          raise ProjectRazor::Error::Slice::MissingArgument, "Must provide a UUID for the policy to remove (or select the '--all' option)"
        end
      end

      # Returns all policy instances
      def get_all_policies
        # Get all policy instances and print/return
        policy_all = get_object("policies", :policy)
        print_object_array @policies.get, "Policies", :style => :table
      end

      # Returns the policy templates available
      def get_policy_templates
        # We use the common method in Utility to fetch object templates by providing Namespace prefix
        print_object_array get_child_templates(ProjectRazor::PolicyTemplate), "\nPolicy Templates:"
      end

      def get_policy_with_uuid(policy_uuid)
        policy = get_object("get_policy_by_uuid", :policy, policy_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Policy with UUID: [#{policy_uuid}]" unless policy
        print_object_array [policy], "", :success_type => :generic
      end

      def get_possible_models
        # TODO - Need to sort out how this method is used so that it can be updated... (tjmcs; 30-Jul-2012)
        @command           = :get_possible_models
        @command_help_text = "razor policy get [model|model_config] [all|(policy template)]"
        # TODO - This parsing get/post/line below for web should be in the Base object or Util. Need to make common and move. Too much repeating
        if @web_command
          # Grab next arg as json string var
          json_string = @command_array.first
          # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
          if is_valid_json?(json_string)
            # Grab vars as hash using sanitize to strip the @ prefix if used
            @vars_hash       = sanitize_hash(JSON.parse(json_string))
            # Policy template (must match a proper policy template)
            @policy_template = @vars_hash['policy_template']
          else
            #Same vars as above but pulled from CLI arg / Web PATH
            @policy_template = @command_array.first
          end
        end
        @policy_template = @command_array.first unless @policy_template
        case @policy_template
          when "all", '{}', nil
            # Just print all models
            print_object_array get_object("models", :model), "All Models"
          else
            possible_models = []
            setup_data
            @data.fetch_all_objects(:model).each do |model|
              possible_models << model if model.template.to_s == @policy_template.to_s
            end
            print_object_array possible_models, "Valid Models for (#{@policy_template.to_s})"
        end
      end

      def get_broker_targets
        # Just print all broker targets
        print_object_array get_object("broker_targets", :broker), "All Broker Target"
      end

      def get_callback
        @command           = :get_callback
        @command_help_text = ""
        active_model_uuid  = @command_array.shift
        raise ProjectRazor::Error::Slice::MissingActiveModelUUID, "Missing active model uuid" unless validate_arg(active_model_uuid)
        callback_namespace = @command_array.shift
        raise ProjectRazor::Error::Slice::MissingCallbackNamespace, "Missing callback namespace" unless validate_arg(callback_namespace)
        engine       = ProjectRazor::Engine.instance
        active_model = nil
        engine.get_active_models.each { |am| active_model = am if am.uuid == active_model_uuid }
        raise ProjectRazor::Error::Slice::ActiveModelInvalid, "Active Model Invalid" unless active_model
        logger.debug "Active bound policy found for callback: #{callback_namespace}"
        make_callback(active_model, callback_namespace)
      end

      def make_callback(active_model, callback_namespace)
        callback = active_model.model.callback[callback_namespace]
        raise ProjectRazor::Error::Slice::NoCallbackFound, "Missing callback" unless callback
        setup_data
        node            = @data.fetch_object_by_uuid(:node, active_model.node_uuid)
        callback_return = active_model.model.callback_init(callback, @command_array, node, active_model.uuid, active_model.broker)
        active_model.update_self
        puts callback_return
      end

      def remove_all_policies
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Policies" unless @data.delete_all_objects(:policy)
        slice_success("All policies removed", :success_type => :removed)
      end

      def remove_policy_with_uuid(policy_uuid)
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide A Policy UUID [policy_uuid]" unless validate_arg(policy_uuid)
        policy = get_object("policy_with_uuid", :policy, policy_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Policy with UUID: [#{policy_uuid}]" unless policy
        setup_data
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove policy [#{tagrule.uuid}]" unless @data.delete_object(policy)
        slice_success("Active policy [#{policy.uuid}] removed", :success_type => :removed)
      end

    end
  end
end


