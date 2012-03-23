# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice

    # ProjectRazor Slice Policy
    # Used for policy rule management
    # @author Nicholas Weaver
    class Policy < ProjectRazor::Slice::Base
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:add => "add_policy",
                           :get => "get_policy",
                           :default => "get_policy",
                           :remove => "remove_policy"}
        @slice_commands_help = {:add => "imagesvc policy add " + "(type)".blue +
                                        "(name)".blue + "(model config uuid)".blue + "(tag;tag;tag)".blue,
                                :get => "imagesvc policy ".red + "{get [rule|type|model [config|type]}".blue,
                                :remove => "imagesvc policy " + "(policy rule UUID)".yellow,
                                :default => "imagesvc policy ".red + "{get [rule|type|model [config|type]}".blue,
                                "get model" => "imagesvc policy get model [config|type] ".white + "(policy type)".red,
                                "get model config" => "imagesvc policy get model config ".white + "(policy type)".red,
                                "get model type" => "imagesvc policy get model type ".white + "(policy type)".red}
        @slice_name = "Policy"
      end


      #### Add

      def add_policy

      end



      ####


      #### Remove


      ####



      #### Get

      def get_policy
        @command = :get
        @arg01 =  @command_array.shift

        case @arg01
          when "rule"
            get_policy_rules
          when "type"
            get_policy_types
          when "model"
            get_model
          when "help"
            slice_error("Help", false)
          else
            get_policy_rules
        end
      end

      def get_policy_rules
        print_policy_rules get_object("policy_rules", :policy_rule)
      end

      def get_policy_types
        policy_rules = ProjectRazor::PolicyRules.instance

        print_policy_types policy_rules.get_types
      end

      def get_model
        @command = "get model"
        @arg02 =  @command_array.shift

        case @arg02
          when "config"
            get_model_config
          when "type"
            get_model_types
          when "help"
            slice_error("Help")
          else
            slice_error("Help")
        end
      end

      def get_model_config
        @command = "get model config"
        policy_type_name =  @command_array.shift

        if policy_type_name == nil
          slice_error("MissingArgument")
        else
          policy_rules = ProjectRazor::PolicyRules.instance
          policy_type = nil
          policy_rules.get_types.each do
          |type|
            policy_type = type.policy_type if policy_type_name == type.policy_type.to_s
          end

          if policy_type != nil
            print_model_configs policy_rules.get_model_configs(policy_type)
          else
            slice_error("PolicyTypeNotFound")
          end
        end
      end

      def get_model_types
        @command = "get model type"
        policy_type_name =  @command_array.shift

        if policy_type_name == nil
          slice_error("MissingArgument")
        else
          policy_rules = ProjectRazor::PolicyRules.instance

          if policy_rules.is_policy_type?(policy_type_name)
            valid_model_types = []
            policy_rules.get_model_types.each do
            |type|
              valid_model_types << type if policy_type_name == type.model_type.to_s
            end
            print_model_types valid_model_types
          else
            slice_error("PolicyTypeNotFound")
          end
        end
      end

      ####








    end
  end
end

