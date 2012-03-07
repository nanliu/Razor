# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "yaml"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice Boot
    # Used for all boot logic by node
    # @author Nicholas Weaver
    class Boot < ProjectRazor::Slice::Base
      include(ProjectRazor::Logging)
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)

        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:default => "boot_called"}
        @slice_commands_help = {:default => "boot"}
        @slice_name = "Boot"
        @engine = ProjectRazor::Engine.instance
      end

      def boot_called
        if @web_command
          @command_query_string = @command_array.shift
          if @command_query_string != "{}" && @command_query_string != nil
            params = JSON.parse(@command_query_string)
            mac_address = params['mac']
            uuid = mac_address.gsub(":","")
            logger.debug "Boot called by Node(MAC: #{mac_address}  UUID:#{uuid})"

            logger.debug "Calling Engine for boot script"
            puts @engine.boot_checkin(uuid)

            return
          end
        end
        slice_error("NotImplemented")
      end
    end
  end
end