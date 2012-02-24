$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"

require "json"
require "colored"
require "logging"

# Root Razor namespace
# @author Nicholas Weaver
module Razor
  module Slice
    # Abstract parent class for all Razor Modules
    # @abstract
    # @author Nicholas Weaver
    class Base
      include(Razor::Logging)

      # Bool for indicating whether this was driven from Node.js
      attr_accessor :web_command

      # Initializes the Slice Base
      # @param [Array] args
      def initialize(args)
        @command_array = args
        @slice_commands = {}
        @web_command = false
      end

      # Default call method for a slice
      # Used by {./bin/razor}
      # Parses the #command_array and determines the action based on #slice_commands for child object
      def slice_call
        # First var in array should be our root command
        @command = @command_array.shift
        # check command and route based on it
        flag = false
        @command = "default" if @command == nil

        @slice_commands.each_pair do
        |cmd_string, method|
          if @command == cmd_string.to_s
            logger.debug "Slice command called: #{@command}"
            self.send(method)
            flag = true
          end
        end

        if @command == "help"
          available_commands(nil)
        else
          slice_error("InvalidCommand") unless flag
        end
      end

      # Called when slice action is successful
      # Returns a json string representing a [Hash] with metadata and response
      # @param [Hash] response
      def slice_success(response)
        return_hash = {}
        return_hash["resource"] = self.class.to_s
        return_hash["command"] = @command
        return_hash["result"] = "success"
        return_hash["errcode"] = 0
        return_hash["response"] = response
        if @web_command
          puts JSON.dump(return_hash)
        else
          print "\n\n#{@slice_name.capitalize}"
          print " #{return_hash["command"]}"
          print "#{return_hash["result"]}"
        end
        logger.debug "(#{return_hash["resource"]}  #{return_hash["command"]}  #{return_hash["result"]})"
      end

      # Called when a slice action triggers an error
      # Returns a json string representing a [Hash] with metadata including error code and message
      # @param [Hash] error
      def slice_error(error)
        @command = "null" if @command == nil

        return_hash = {}
        return_hash["slice"] = self.class.to_s
        return_hash["command"] = @command
        return_hash["errcode"] = 1
        return_hash["result"] = error
        if @web_command
          puts JSON.dump(return_hash)
        else
          available_commands(return_hash)
        end
        logger.error "Slice error: #{return_hash.inspect}"
      end

      # Prints available commands to CLI for slice
      # @param [Hash] return_hash
      def available_commands(return_hash)
        print "\nAvailable commands for [#{@slice_name}]:\n"
        @slice_commands.each do
        |k,y|
          print "[#{k}] ".yellow unless k == :default
        end
        print "\n\n"
        if return_hash != nil
          print "[#{@slice_name.capitalize}] "
          print "[#{return_hash["command"]}] ".red
          print "<-#{return_hash["result"]}\n".yellow
          puts "\nCommand syntax: #{@slice_commands_help[@command]}".red unless @slice_commands_help[@command] == nil
        end
      end

      # Initializes [Razor::Data] in not already instantiated
      def setup_data
        @data = Razor::Data.new unless @data.class == Razor::Data
      end
    end
  end
end