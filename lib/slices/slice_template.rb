$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"

require "slice_base"
require "json"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Slice Template
  # Template
  # @author Nicholas Weaver
  class Template < Razor::Slice::Base

    def initialize(args)
      super(args)
      # Define your commands and help text
      @slice_commands = {"command_name" => "method"}
      @slice_commands_help = {"command_name" => "help text"}
      @slice_name = "Template"
    end

  end
end