$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"

require "slice_base"
require "yaml"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Node Module
  # Handles all Node management
  # @author Nicholas Weaver
  class Node < Razor::Slice::Base

    def slice_call
      command = @command_array.shift
      case command
        when "discover"
          if @command_array.count == 3
            uuid = @command_array.shift
            state = @command_array.shift
            attr_hash = YAML.load(@command_array.shift)
            puts "Discovering Node: #{uuid} with reported state: #{state}"
            attr_hash.each_pair {|x,y| puts "\t #{x} == #{y}"}
          else
            slice_error
          end
        else
          slice_error
      end
    end
  end
end