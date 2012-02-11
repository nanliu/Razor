$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"

require "slice_base"
require "json"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Slice Template
  # Template
  # @author Nicholas Weaver
  class Config < Razor::Slice::Base

    def initialize(args)
      super(args)
      # Define your commands and help text
      @slice_commands = {"read" => "read_config"}
      @slice_commands_help = {"read" => "config [read]"}
      @slice_name = "Config"
    end

    def read_config
      setup_data # inits our Razor::Data if it doesn't exist
      if @web_command # is this a web command
        print @data.config.to_hash.to_json
      else
        puts "Razor Config:"
        @data.config.to_hash.each do
        |key,val|
          print "\t#{key.sub("@","")}: ".white
          print "#{val} \n".green
        end
      end

    end
  end
end