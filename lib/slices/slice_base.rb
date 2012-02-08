require "json"
require "colored"

# Root Razor namespace
# @author Nicholas Weaver
module Razor
  module Slice
    # Abstract parent class for all Razor Modules
    # @abstract
    # @author Nicholas Weaver

    class Base

      attr_accessor :web_command
      # [Array] @command_array
      # [Hash] @slice_commands
      def initialize(args)
        @command_array = args
        @slice_commands = {}
        @web_command = false
      end

      def slice_call
        while @command_array.count > 0
          puts "\t#{@command_array.shift}"
        end
      end

      def slice_success
        return_hash = {}
        return_hash["slice"] = self.class.to_s
        return_hash["command"] = @command
        return_hash["result"] = "Success"
        if @web_command
          puts JSON.dump(return_hash).inspect
        else
          print "\n\n#{@slice_name.capitalize}"
          print " #{return_hash["command"]}"
          print "#{return_hash["result"]}"
        end
      end

      def slice_error(error)
        @command = "null" if @command == nil

        return_hash = {}
        return_hash["slice"] = self.class.to_s
        return_hash["command"] = @command
        return_hash["result"] = error
        if @web_command
          puts JSON.dump(return_hash).inspect
        else
          print "\nAvailable commands for [#{@slice_name}]:\n"
          @slice_commands.each do
          |k,y|
            print "[#{k}] ".yellow
          end
          print "\n\n"
          print "[#{@slice_name.capitalize}] "
          print "[#{return_hash["command"]}] ".red
          print "<-#{return_hash["result"]}\n".yellow
          puts "\nCommand syntax: #{@slice_commands_help[@command]}".red unless @slice_commands_help[@command] == nil
        end
      end
    end
  end
end