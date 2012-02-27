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

    def boot_called
      if @web_command
        @command_query_string = @command_array.shift
        if @command_query_string != "{}" && @command_query_string != nil
          params = JSON.parse(@command_query_string)
          mac_address = params['mac']
          logger.debug "Boot called by Node(MAC: #{mac_address}"
          # todo call engine with uuid
          # prove out boot script can pull razor server from existing ixe var
          # junk stub code to make ipxe boot work, calls razor image
          puts "#!ipxe\ninitrd http://192.168.99.10:8027/razor/image/mk || reboot\nchain http://192.168.99.10:8027/razor/image/memdisk iso || reboot"
          return
        end
      end
      slice_error("NotImplemented")
    end
  end

end