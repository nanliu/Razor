# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "data"
require "logging"

# Root Razor namespace
# @author Nicholas Weaver
module Razor

  # Used for all event-driven commands and policy resolution
  # @author Nicholas Weaver
  class Engine
    include(Razor::Logging)

    def initialize
      @data = Razor::Data.new

    end

    # TODO policy resolve


    # TODO tag rules resolve


    def get_boot(uuid)
      logger.debug "Getting boot for uuid:#{uuid}"


      boot_script = ""
      boot_script << "#!ipxe\n"
      boot_script << "initrd http://192.168.99.10:8027/razor/image/mk\n"
      boot_script << "chain http://192.168.99.10:8027/razor/image/memdisk iso"
      boot_script
    end


    def tag_node

    end






  end
end
