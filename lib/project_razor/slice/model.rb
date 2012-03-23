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
                                :default => "imagesvc model ".red + "{get [config|type]}".blue,
                                :add_cli => "imagesvc model add".red + " (model_type) (model config name)".blue,
                                :add_web => "imagesvc model add".red + " (model_type) (json string)".blue}
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

      def get_model_types
        policy_rules = ProjectRazor::PolicyRules.instance
        print_model_types policy_rules.get_model_types
      end

      def add_model
        if @web_command
          # REST call
          add_model_web
        else
          # CLI call
          add_model_cli
        end
      end

      def add_model_cli
        @command = :add_cli
        @model_name =  @command_array.shift
        policy_rules = ProjectRazor::PolicyRules.instance

        unless @model_name != nil
          slice_error("ModelTypeMissing")
          return
        end


        new_model = policy_rules.is_model_type?(@model_name)
        unless new_model
          slice_error("ModelTypeNotFound")
          return
        end

        @model_config_name =  @command_array.shift
        unless @model_name != nil
          slice_error("ModelNameMissing")
          return
        end

        if new_model.req_metadata_hash != {}
           new_model = cli_interactive_metadata(new_model.req_metadata_hash)
        else

        end



      end


      def cli_interactive_metadata(req_metadata_hash)
        #@req_metadata_hash = {
        #    "@hostname" => {:default => "hostname.example.org", :validation => '\S', :required => true}
        #}
        puts "\n\t Building Model Config:"
        req_metadata_hash.each_key do
          |md|
          puts "\tPlease enter #{md[:description]}"
          puts "\t\t example: #{md[:example]}"
          puts "\t\t default: #{md[:default]}" if md[:default] != ""
          response = gets

          puts response
        end
        nil

      end

      def add_model_web
        @command = :add_web
        @model_type =  @command_array.shift
        @values_json_string =  @command_array.shift
        slice_error("NotImplemented")
      end




    end
  end
end