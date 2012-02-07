$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"

require "slice_base"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
    # Razor Slice Boot
    # Returns boot scripts based on Node selected
    # @author Nicholas Weaver
    class Boot < Razor::Slice::Base
    end
end