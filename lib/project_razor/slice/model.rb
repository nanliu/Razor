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
        load_model_types # load our model types

        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:default => "query_models",
                           :type => "query_model_types",
                           :create => "create_model",
                           :remove => "remove_node",
                           :list => "query_model"}
        @slice_commands_help = {:list => "model list",
                                :default => "model"}
        @slice_name = "Node"
      end


      def query_model_types
        temp_hash = {}
        ObjectSpace.each_object do
        |object_class|

          if object_class.to_s.start_with?(MODEL_PREFIX) && object_class.to_s != MODEL_PREFIX
            temp_hash[object_class.to_s] = object_class.to_s.sub(MODEL_PREFIX,"").strip
          end
        end
        @slice_array = {}
        temp_hash.each_value {|x| @slice_array[x] = x}
        @slice_array = @slice_array.each_value.collect {|x| x}

        @slice_array.each do
        |x|
          #puts MODEL_PREFIX + x
          o = Object.full_const_get(MODEL_PREFIX + x).new(nil)
          puts o.model_description
        end
      end


      def load_model_types
        Dir.glob("#{MODEL_TYPE_PATH}/*.{rb}") do |file|
          require "#{file}"
        end
      end
    end
  end
end