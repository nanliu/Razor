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
        @slice_commands_help = {:add => "imagesvc add_rule " + "(type)".blue + " (PATH TO ISO)".yellow,
                                :get => "imagesvc policy {get [rule|type]}".blue,
                                :remove => "imagesvc remove " + "(IMAGE UUID)".yellow,
                                :default => "imagesvc " + "[get]".blue}
        @slice_name = "Policy"
      end


      def get_policy
        @arg01 =  @command_array.shift

        case @arg01
          when "rule"
            get_policy_rules
          when "type"
            get_policy_types
          when "help"
            slice_error("", false)
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


      # Handles printing of image details to CLI
      # @param [Array] images_array
      def print_policy_rules(rules_array)
        unless @web_command
          puts "Policy Rules:"

          #unless @verbose
          #  rules_array.each do
          #  |rule|
          #    rule.print_image_info(@data.config.image_svc_path)
          #    print "\n"
          #  end
          #else
          rules_array.each { |rule| print_object_details_cli(rule) }
        else
          rules_array = rules_array.collect { |rule| rule.to_hash }
          slice_success(rules_array, false)
        end
      end

      def print_policy_types(types_array)
        unless @web_command
          puts "Policy Types:"
          unless @verbose
            types_array.each { |type| puts "\t#{type.policy_type} ".yellow + " :  #{type.description}" }
          else
            types_array.each { |type| print_object_details_cli(type) }
          end
        else
          types_array = types_array.collect { |type| type.to_hash }
          slice_success(types_array, false)
        end
      end



    end
  end
end

