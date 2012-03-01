# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

Dir.glob(ENV['RAZOR_HOME'] + '/lib/**/').each {|x| $LOAD_PATH << x} # adds Razor lib/dirs to load path


require "data"
require "slice_base"
require "json"
require "logging"
require "yaml"
require "engine"

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
      @engine = Razor::Engine.new
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
          puts @engine.get_boot(uuid)

          return
        end
      end
      slice_error("NotImplemented")
    end
  end

end