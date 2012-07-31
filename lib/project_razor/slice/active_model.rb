require "json"


# Root ProjectRazor namespace
module ProjectRazor
  module Slice

    # ProjectRazor Slice Active_Model
    class Active_model < ProjectRazor::Slice::Base
      def initialize(args)
        super(args)
        @hidden          = false
        @new_slice_style = true
        @slice_commands  = {
            :get  => "get_active_model",
            :default => :get,
            :logview => "get_logview",
            :remove => "remove_active_model",
            :else => :get,
            ["--help", "-h"] => "active_model_help"
        }
        @slice_name      = "Active_model"
        @policies        = ProjectRazor::Policies.instance
      end

      def active_model_help
        puts "Active Model Slice: used to view active models or active model logs, and to remove active models.".red
        puts "Active Model Commands:".yellow
        puts "\trazor active_model [get] [--all]          " + "View all active models".yellow
        puts "\trazor active_model [get] (UUID) [--log]   " + "View specific active model (log)".yellow
        puts "\trazor active_model logview                " + "Prints an aggregate active model log view".yellow
        puts "\trazor active_model remove (UUID)|(--all)  " + "Remove existing (or all) active model(s)".yellow
        puts "\trazor active_model --help                 " + "Display this screen".yellow
      end

      def get_active_model
        @command = :get_active_model
        @command_help_text << "Description: Gets the properties associated with one or more Active Models\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :get)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        active_model_uuid, options = parse_and_validate_options(option_items, "razor active_model get [UUID] [OPTION]", :require_all)
        if !@web_command
          active_model_uuid = @command_array.shift
        end
        includes_uuid = true if active_model_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        selected_option = options.select { |k, v| v }.keys[0].to_s
        if options[:logs]
          # get log events for the selected active_model
          get_active_model_logs(active_model_uuid)
        elsif includes_uuid
          # get the details for a specific node
          get_active_model_by_uuid(active_model_uuid)
        else
          # get a summary view of all nodes; will end up here
          # if the option chosen is the :all option (or if nothing but the
          # 'get' subcommand was specified as this is the default action)
          get_active_model_all
        end
      end

      def remove_active_model
        @command = :remove_active_model
        @command_help_text << "Description: Remove one (or all) Active Models from Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :remove)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        active_model_uuid, options = parse_and_validate_options(option_items, "razor active_model remove (UUID)|(--all)", :require_all)
        if !@web_command
          active_model_uuid = @command_array.shift
        end
        includes_uuid = true if active_model_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        selected_option = options.select { |k, v| v }.keys[0].to_s
        if options[:all]
          # remove all Active Models from the system
          remove_all_active_models
        elsif includes_uuid
          # remove a specific Active Model (by UUID); this is the default
          # action if no options are specified (the only option currently for
          # this subcommand is the '--all' option)
          remove_active_model_by_uuid(active_model_uuid)
        else
          # if get to here, no UUID was specified and the '--all' option was
          # no included, so raise an error and exit
          raise ProjectRazor::Error::Slice::MissingArgument, "Must provide a UUID for the active_model to remove (or select the '--all' option)"
        end
      end

      def get_active_model_all
        # Get all active model instances and print/return
        @command_array.unshift(@last_arg) unless @last_arg == 'default'
        print_object_array get_object("active_models", :active), "Active Models:", :success_type => :generic, :style => :table
      end

      def get_active_model_by_uuid(uuid)
        active_model = get_object("active_model_instance", :active, uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Active Model with UUID: [#{uuid}]" unless active_model
        print_object_array [active_model], "", :success_type => :generic
      end

      def get_active_model_logs(uuid)
        active_model = get_object("active_model_instance", :active, uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Active Model with UUID: [#{uuid}]" unless active_model
        print_object_array [active_model], "", :success_type => :generic, :style => :table
        print_object_array(active_model.print_log, "", :style => :table)
      end

      def remove_all_active_models
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Active Models" unless get_data.delete_all_objects(:active)
        slice_success("All active models removed", :success_type => :removed)
      end

      def remove_active_model_by_uuid(uuid)
        active_model = get_object("active_model_instance", :active, uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Active Model with UUID: [#{uuid}]" unless active_model
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Active Model [#{active_model.uuid}]" unless get_data.delete_object(active_model)
        slice_success("Active model #{active_model.uuid} removed", :success_type => :removed)
      end

      def get_logview
        active_models = get_object("active_models", :active)
        log_items = []
        active_models.each { |bp| log_items = log_items | bp.print_log_all }
        log_items.sort! { |a, b| a.print_items[3] <=> b.print_items[3] }
        log_items.each { |li| li.print_items[3] = Time.at(li.print_items[3]).strftime("%H:%M:%S") }
        print_object_array(log_items, "All Active Model Logs:", :success_type => :generic, :style => :table)
      end

    end
  end
end


