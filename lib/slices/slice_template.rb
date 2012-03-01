# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

Dir.glob(ENV['RAZOR_HOME'] + '/lib/**/').each {|x| $LOAD_PATH << x} # adds Razor lib/dirs to load path

require "slice_base"
require "json"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Slice Template
  # Template
  # @author Nicholas Weaver
  class Template < Razor::Slice::Base

    # init
    # @param [Array] args
    def initialize(args)
      super(args)
      # Define your commands and help text
      @slice_commands = {"command_name" => "method"}
      @slice_commands_help = {"command_name" => "help text"}
      @slice_name = "Template"
    end

  end
end