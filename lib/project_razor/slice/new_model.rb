# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

MODEL_PREFIX = "ProjectRazor::ModelTemplate::"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice Model
    # @author Nicholas Weaver
    class New_model < ProjectRazor::Slice::Base
      include(ProjectRazor::Logging)
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = false
        @new_slice_style = true
        @slice_commands = {:add => "add_model",
                           :get => {
                               :default => "get_all_models",
                               :else => "get_model_by_uuid",
                               :template => {
                                   :default => "get_all_templates",
                                   :else => "get_template_by_name"
                               },
                           },
                           :update => {},
                           :remove => {},
                           :default => "get_all_models",
                           :else => :get,
                           :help => ""}
        @slice_name = "New_model"
      end


      def get_all_models
        # Get all tag rules and print/return
        @command = :get_all_models
        @command_array.unshift(@last_arg) unless @last_arg == 'default'
        print_object_array get_object("models", :model), "Models", :style => :table, :success_type => :generic
      end

      def get_model_by_uuid
        @command = :get_model_by_uuid
        @command_help_text = "razor model [get] (uuid)"
        model = get_object("get_model_by_uuid", :model, @command_array.first)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Model with UUID: [#{@command_array.first}]" unless model
        print_object_array [model] ,"",:success_type => :generic
      end

      def get_all_templates
        # We use the common method in Utility to fetch object templates by providing Namespace prefix
        print_object_array get_child_templates(MODEL_PREFIX), "Model Templates:"
      end

      def add_model
        @command =:add_model
        @command_help_text = "razor model add template=(model template) label=(model label) {image_uuid=(Image UUID)}\n"
        @command_help_text << "\t template: \t" + " The Model Template name to use\n".yellow
        @command_help_text << "\t label: \t" + " A label to name this Model\n".yellow
        @command_help_text << "\t image_uuid: \t" + " If the Model Template requires an Image, the Image UUID\n".yellow
        template, label, image_uuid, req_metadata_hash =
            *get_web_vars(%w(template label image_uuid req_metadata_hash)) if @web_command
        template, label, image_uuid =
            *get_cli_vars(%w(template label image_uuid)) unless template || label || image_uuid
        # Validate our args are here
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide A Model Template [template]" unless validate_arg(template)
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide A Model Label [label]" unless validate_arg(label)
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide A Image UUID [image_uuid]" unless validate_arg(image_uuid)
        model = verify_template(template)
        raise ProjectRazor::Error::Slice::InvalidModelTemplate, "Invalid Model Template [#{template}] " unless model
        image = verify_image(model, image_uuid) if model.image_prefix
        unless image
          raise ProjectRazor::Error::Slice::InvalidUUID, "Invalid Image UUID [#{image_uuid}] "
        end
        if @web_command
          raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide A Model Template [template]" unless validate_arg(req_metadata_hash)
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

      def verify_template(template_name)
        get_child_templates(MODEL_PREFIX).each { |template| return template if template.name == template_name }
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
