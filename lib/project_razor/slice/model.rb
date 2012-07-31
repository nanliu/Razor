require 'json'

# Root ProjectRazor namespace
module ProjectRazor
  module Slice
    # ProjectRazor Slice Model
    class Model < ProjectRazor::Slice::Base
      include(ProjectRazor::Logging)
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = false
        @new_slice_style = true
        @slice_commands = {:add => "add_model",
                           :get => "get_model",
                           :update => "update_model",
                           :remove => "remove_model",
                           :default => :get,
                           :else => :get,
                           ["--help", "-h"] => "model_help"}
        @slice_name = "Model"
      end

      def model_help
        puts "Model Slice: used to add, view, update, and remove models.".red
        puts "Model Commands:".yellow
        puts "\trazor model [get] [--all]            " + "View all broker targets".yellow
        puts "\trazor model [get] (UUID)             " + "View specific broker target".yellow
        puts "\trazor model add (UUID) (OPTIONS)     " + "View specific broker target".yellow
        puts "\trazor model update (UUID) (OPTIONS)  " + "View specific broker target".yellow
        puts "\trazor model remove (UUID)|(--all)    " + "Remove existing (or all) broker target(s)".yellow
        puts "\trazor model --help                   " + "Display this screen".yellow
      end

      def get_model
        @command = :get_model
        @command_help_text << "Description: Gets the properties associated with one or more Models\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :get)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        model_uuid, options =
            parse_and_validate_options(option_items, "razor model get [UUID]|[--all]|[--template]",
                                       :require_all)
        if !@web_command
          model_uuid = @command_array.shift
        end
        includes_uuid = true if model_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        if options[:template]
          # get the list of attributes for the chosen node
          get_all_templates
        elsif includes_uuid
          # get the details for a specific node
          get_model_with_uuid(model_uuid)
        else
          # get a summary view of all nodes; will end up here
          # if the option chosen is the :all option (or if nothing but the
          # 'get' subcommand was specified as this is the default action)
          get_all_models
        end
      end

      def add_model
        @command = :add_model
        @command_help_text << "Description: Used to add a new Model to Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "razor model add (OPTIONS)", :require_all)
        includes_uuid = true if tmp
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        template = options[:template]
        label = options[:label]
        image_uuid = options[:image_uuid]
        # check the values that were passed in
        model = verify_template(template)
        raise ProjectRazor::Error::Slice::InvalidModelTemplate, "Invalid Model Template [#{template}] " unless model
        image = model.image_prefix ? verify_image(model, image_uuid) : true
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Image UUID [#{image_uuid}] " unless image
        # use the arguments passed in (above) to create a new model
        if @web_command
          raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Required Metadata [req_metadata_hash]" unless
              req_metadata_hash
          model.web_create_metadata(req_metadata_hash)
        else
          raise ProjectRazor::Error::Slice::UserCancelled, "User cancelled Model creation" unless model.cli_create_metadata
        end
        model.label = label
        model.image_uuid = image.uuid
        model.is_template = false
        setup_data
        @data.persist_object(model)
        model ? print_object_array([model], "Model created", :success_type => :created) : raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Model")
      end

      def update_model
        @command = :update_model
        @command_help_text << "Description: Used to update an existing Model\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        model_uuid, options = parse_and_validate_options(option_items, "razor model update UUID (OPTIONS)", :require_one)
        if !@web_command
          model_uuid = @command_array.shift
        end
        includes_uuid = true if model_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        label = options[:label]
        image_uuid = options[:image_uuid]
        change_metadata = options[:change_metadata]
        # check the values that were passed in (and gather new meta-data if
        # the --change-metadata flag was included in the update command)
        model = get_object("model_with_uuid", :model, model_uuid)
        if @web_command
          if req_metadata_hash
            model.web_create_metadata(req_metadata_hash)
          end
        else
          if change_metadata
            raise ProjectRazor::Error::Slice::UserCancelled, "User cancelled Model creation" unless
                model.cli_create_metadata
          end
        end
        model.label = label if label
        image = model.image_prefix ? verify_image(model, image_uuid) : true if image_uuid
        raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Image UUID [#{image_uuid}] " unless image || !image_uuid
        model.image_uuid = image.uuid if image
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Model [#{model.uuid}]" unless model.update_self
        print_object_array [model] ,"",:success_type => :updated
      end

      def remove_model
        @command = :remove_model
        @command_help_text << "Description: Remove one (or all) Models from Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :remove)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        model_uuid, options = parse_and_validate_options(option_items, "razor model remove (UUID)|(--all)", :require_all)
        if !@web_command
          model_uuid = @command_array.shift
        end
        includes_uuid = true if model_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        # selected_option = options.select { |k, v| v }.keys[0].to_s
        if options[:all]
          # remove all Active Models from the system
          remove_all_models
        elsif includes_uuid
          # remove a specific Active Model (by UUID); this is the default
          # action if no options are specified (the only option currently for
          # this subcommand is the '--all' option)
          remove_model_by_uuid(model_uuid)
        else
          # if get to here, no UUID was specified and the '--all' option was
          # no included, so raise an error and exit
          raise ProjectRazor::Error::Slice::MissingArgument, "Must provide a UUID for the model to remove (or select the '--all' option)"
        end
      end

      def get_all_models
        # Get all tag rules and print/return
        @command = :get_all_models
        @command_array.unshift(@last_arg) unless @last_arg == 'default'
        print_object_array get_object("models", :model), "Models", :style => :table, :success_type => :generic
      end

      def get_model_with_uuid(model_uuid)
        model = get_object("get_model_by_uuid", :model, model_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model
        print_object_array [model] ,"",:success_type => :generic
      end

      def get_all_templates
        # We use the common method in Utility to fetch object templates by providing Namespace prefix
        print_object_array get_child_templates(ProjectRazor::ModelTemplate), "Model Templates:"
      end

      def verify_template(template_name)
        get_child_templates(ProjectRazor::ModelTemplate).each { |template| return template if template.name == template_name }
        nil
      end

      def verify_image(model, image_uuid)
        setup_data
        image = get_object("find_image", :images, image_uuid)
        if image
          return image if model.image_prefix == image.path_prefix
        end
        nil
      end

      def remove_all_models
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Tag Rules" unless @data.delete_all_objects(:model)
        slice_success("All Models removed",:success_type => :removed)
      end

      def remove_model_by_uuid(model_uuid)
        model = get_object("model_with_uuid", :model, model_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model
        setup_data
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Model [#{tagrule.uuid}]" unless @data.delete_object(model)
        slice_success("Active Model [#{model.uuid}] removed",:success_type => :removed)
      end

    end
  end
end
