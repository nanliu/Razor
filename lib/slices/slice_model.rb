$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/models"
MODEL_TYPE_PATH = "#{ENV['RAZOR_HOME']}/lib/models"
MODEL_PREFIX = "Razor::Model::"

require "data"
require "model_base"
require "slice_base"
require "json"
require "logging"
require "yaml"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Slice Model
  # @author Nicholas Weaver
  class Model < Razor::Slice::Base
    include(Razor::Logging)
    # Initializes Razor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
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