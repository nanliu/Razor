# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice Template
    # Template
    # @author Nicholas Weaver
    class Config < ProjectRazor::Slice::Base

      # init
      # @param [Array] args
      def initialize(args)
        super(args)
        # Define your commands and help text
        @slice_commands = {:read => "read_config",
                           :default => "read_config"}
        @slice_commands_help = {:read => "config [read]"}
        @slice_name = "Config"
      end

      # Reads the ProjectRazor config
      def read_config
        setup_data
        if @web_command # is this a web command
          print @data.config.to_hash.to_json
        else
          puts "ProjectRazor Config:"
          @data.config.to_hash.each do
          |key,val|
            print "\t#{key.sub("@","")}: ".white
            print "#{val} \n".green
          end
        end

      end
    end
  end
end