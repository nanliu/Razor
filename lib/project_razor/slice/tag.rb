# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice

    # ProjectRazor Slice Tag
    # Used for managing the tagging system
    # @author Nicholas Weaver
    class Tag < ProjectRazor::Slice::Base
      # Initializes ProjectRazor::Slice::Tag
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = false
        @new_slice_style = true
        @slice_commands = {:add => "add_tagrule",
                           :get => {
                               :default => "get_all_tagrules",
                               :else => "get_tagrule_with_uuid",
                           },
                           :update => {
                               :default => "get_all_tagrules",
                               :else => "update_tagrule"
                           },
                           :remove => {
                               :all => "remove_all_tagrules",
                               :default => "get_all_tagrules",
                               :else => "remove_tagrule"
                           },
                           :default => "get_all_tagrules",
                           :else => :get,
                           :help => ""}
        @slice_name = "Tag"
      end

      def get_all_tagrules
        # Get all node instances and print/return
        @command = :get_all_tagrules
        @command_array.unshift(@last_arg) unless @last_arg == 'default'
        print_object_array get_object("tagrules", :tag), "Tag Rules", :style => :table, :success_type => :generic
      end

      def get_tagrule_with_uuid
        @command = :get_tagrule_with_uuid
        @command_help_text = "razor tag [get] (uuid)"
        tagrule = get_object("tagrule_with_uuid", :tag, @command_array.first)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{@command_array.first}]" unless tagrule
        print_object_array [tagrule] ,"",:success_type => :generic
      end

      def add_tagrule
        @command =:add_tagrule
        @command_help_text = "razor tag add {name=(name)} {tag=(tag)}"
        @name, @tag = *get_web_vars(%w(name tag)) if @web_command
        @name, @tag = *get_cli_vars(%w(name tag)) unless @name || @tag
        # Validate our args are here
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Tag Rule Name [name]" unless validate_arg(@name)
        raise ProjectRazor::Error::Slice::MissingArgument, "Must Provide Tag Rule Tag [tag]" unless validate_arg(@tag)
        tagrule = ProjectRazor::Tagging::TagRule.new({"@name" => @name, "@tag" => @tag})
        setup_data
        @data.persist_object(tagrule)
        tagrule ? print_object_array([tagrule], "", :success_type => :created) : raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Tag Rule")
      end

      def update_tagrule
        @command = :update_tagrule
        @command_help_text = "razor tag update (UUID) {name=(name)} {tag=(tag)}"
        tagrule_uuid = @command_array.shift
        tagrule = get_object("tagrule_with_uuid", :tag, tagrule_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tagrule_uuid}]" unless tagrule
        @name, @tag = *get_web_vars(%w(name tag)) if @web_command
        @name, @tag = *get_cli_vars(%w(name tag)) unless @name || @tag
        raise ProjectRazor::Error::Slice::MissingArgument, "Must provide at least one value to update" unless @name || @tag
        tagrule.name = @name if @name
        tagrule.tag = @tag if @tag
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Tag Rule [#{tagrule.uuid}]" unless tagrule.update_self
        print_object_array [tagrule] ,"",:success_type => :updated
      end

      def remove_all_tagrules
        @command = :remove_tagrule
        @command_help_text = "razor tag remove all"
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Tag Rules" unless @data.delete_all_objects(:tag)
        slice_success("All Tag Rules removed",:success_type => :removed)
      end

      def remove_tagrule
        @command = :remove_tagrule
        @command_help_text = "razor tag remove (UUID)"
        tagrule_uuid = @command_array.shift
        tagrule = get_object("tagrule_with_uuid", :tag, tagrule_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tagrule_uuid}]" unless tagrule
        setup_data
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Tag Rule [#{tagrule.uuid}]" unless @data.delete_object(tagrule)
        slice_success("Tag Rule [#{tagrule.uuid}] removed",:success_type => :removed)
      end

    end
  end
end

