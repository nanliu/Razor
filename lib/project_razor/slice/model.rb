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
        @slice_name = "Model"
        # get the slice commands map for this slice (based on the set
        # of commands that are typical for most slices)
        @slice_commands = get_command_map("model_help",
                                          "get_all_models",
                                          "get_model_by_uuid",
                                          "add_model",
                                          "update_model",
                                          "remove_all_models",
                                          "remove_model_by_uuid")
        # and add any additional commands specific to this slice
        @slice_commands[:get].delete(/^[\S]+$/)
        @slice_commands[:get][:else] = "get_model_by_uuid"
        @slice_commands[:get][[/^(temp|template|templates|types)$/]] = "get_all_templates"
      end

      def model_help
        puts get_model_help
      end

      def get_model_help
        return ["Model Slice: used to add, view, update, and remove models.".red,
                "Model Commands:".yellow,
                "\trazor model [get] [--all]               " + "View all broker targets".yellow,
                "\trazor model [get] (UUID)                " + "View specific broker target".yellow,
                "\trazor model add (UUID) (options...)     " + "View specific broker target".yellow,
                "\trazor model update (UUID) (options...)  " + "View specific broker target".yellow,
                "\trazor model remove (UUID)|(--all)       " + "Remove existing (or all) broker target(s)".yellow,
                "\trazor model --help                      " + "Display this screen".yellow].join("\n")
      end

      def get_all_models
        @command = :get_all_models
        # Get all tag rules and print/return
        print_object_array get_object("models", :model), "Models", :style => :table, :success_type => :generic
      end

      def get_model_by_uuid
        @command = :get_model_by_uuid
        # the UUID is the first element of the @command_array
        model_uuid = @command_array.first
        model = get_object("get_model_by_uuid", :model, model_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model
        print_object_array [model] ,"",:success_type => :generic
      end

      def get_all_templates
        @command = :get_all_templates
        # We use the common method in Utility to fetch object templates by providing Namespace prefix
        print_object_array get_child_templates(ProjectRazor::ModelTemplate), "Model Templates:"
      end

      def add_model
        @command = :add_model
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "razor model add (options...)", :require_all)
        includes_uuid = true if tmp && tmp != "add"
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        template = options[:template]
        label = options[:label]
        image_uuid = options[:image_uuid]
        # TODO; sort out how to pass in the req_metadata_hash value using the existing YAML files for add and update
        # req_metadata_hash = options[:req_metadata_hash]
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
        includes_uuid = false
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        model_uuid, options = parse_and_validate_options(option_items, "razor model update UUID (options...)", :require_one)
        includes_uuid = true if model_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        label = options[:label]
        image_uuid = options[:image_uuid]
        change_metadata = options[:change_metadata]
        # req_metadata_hash = options[:req_metadata_hash]

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

      def remove_all_models
        @command = :remove_all_models
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Tag Rules" unless @data.delete_all_objects(:model)
        slice_success("All Models removed",:success_type => :removed)
      end

      def remove_model_by_uuid
        @command = :remove_model_by_uuid
        # the UUID was the last "previous argument"
        model_uuid = get_uuid_from_prev_args
        model = get_object("model_with_uuid", :model, model_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{model_uuid}]" unless model
        setup_data
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Model [#{model.uuid}]" unless @data.delete_object(model)
        slice_success("Active Model [#{model.uuid}] removed",:success_type => :removed)
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

    end
  end
end
