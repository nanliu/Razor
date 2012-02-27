# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "data"

# Root Razor namespace
# @author Nicholas Weaver
module Razor

  # Used for all event-driven commands and policy resolution
  # @author Nicholas Weaver
  class Engine

    def initialize
      @data = Razor::Data.new

    end

    # TODO policy resolve


    # TODO tag rules resolve


    def get_boot(uuid)

    end




  end
end
