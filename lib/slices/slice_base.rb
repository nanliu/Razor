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

      # Default call method for a slice. Used by {razor.rb}.
      def slice_call
        # First var in array should be our root command
        @command = @command_array.shift
        # check command and route based on it
        flag = false
        @slice_commands.each_pair do
        |cmd_string, method|
          if @command == cmd_string
            self.send(method)
            flag = true
          end
        end
        slice_error("InvalidCommand") unless flag
      end

      def slice_success
        return_hash = {}
        return_hash["slice"] = self.class.to_s
        return_hash["command"] = @command
        return_hash["result"] = "Success"
        if @web_command
          puts JSON.dump(return_hash)
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
          puts JSON.dump(return_hash)
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

      def setup_data
        @data = Razor::Data.new unless @data.class == Razor::Data
      end
    end
  end
end