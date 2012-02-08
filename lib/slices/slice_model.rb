$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"

require "slice_base"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
    # Razor Slice Model
    # @author Nicholas Weaver
    class Model < Razor::Slice::Base
    end
end