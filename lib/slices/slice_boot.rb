$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"

require "data"
require "slice_base"
require "json"
require "logging"
require "yaml"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Slice Boot
  # Used for all boot logic by node
  # @author Nicholas Weaver
  class Boot < Razor::Slice::Base
    include(Razor::Logging)
    # Initializes Razor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
    # @param [Array] args
    def initialize(args)
      super(args)

      # Here we create a hash of the command string to the method it corresponds to for routing.
      @slice_commands = {:default => "boot_called"}
      @slice_commands_help = {:default => "boot"}
      @slice_name = "Boot"
    end
  end

end