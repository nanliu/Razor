

# Root Razor namespace
# @author Nicholas Weaver
module Razor
  module Slice
    # Abstract parent class for all Razor Modules
    # @abstract
    # @author Nicholas Weaver

    class Base

      def initialize(args)
        @command_array = args
      end

      def slice_call
        while @command_array.count > 0
          puts "\t#{@command_array.shift}"
        end
      end

      def slice_error
        puts "\t#{self.class.to_s}: InvalidRequest"
      end

    end
  end
end