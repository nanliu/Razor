# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice

    # ProjectRazor Slice System
    # Used for system management
    # @author Nicholas Weaver
    class System < ProjectRazor::Slice::Base
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:add => "add_system",
                           :get => "get_system",
                           :default => "get_system",
                           :remove => "remove_system"}
        @slice_commands_help = {:get => "system ".red + "[type|(System UUID)]".blue,
                                :add => "system " + "(system type) (Name) (Description) [options..]".yellow,
                                :remove => "system " + "(System UUID)".yellow,
                                :default => "system ".red + "[type|(System UUID)]".blue}
        @slice_name = "System"
      end


    end
  end
end

