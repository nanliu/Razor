# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "yaml"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice Model
    # @author Nicholas Weaver
    class Model < ProjectRazor::Slice::Base
      include(ProjectRazor::Logging)
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:default => "get_model",
                           :get => "get_model",
                           :add => "add_model",
                           :remove => "remove_model"}
        @slice_commands_help = {:get => "imagesvc model ".red + "{get [config|type]}".blue,
                                :default => "imagesvc model ".red + "{get [config|type]}".blue,}
        @slice_name = "Model"
      end

      def get_model
        @command = :get
        @arg01 =  @command_array.shift

        case @arg01
          when "config"
            get_model_config
          when "type"
            get_model_types
          when "help"
            slice_error("Help", false)
          else
            get_model_config
        end
      end


      def get_model_config
        print_model_configs get_object("model_config", :model)
      end

      def get_model_type
        policy_rules = ProjectRazor::PolicyRules.instance
        print_model_types policy_rules.get_model_types
      end




    end
  end
end