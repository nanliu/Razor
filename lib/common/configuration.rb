# Razor config - this is imported via a YAML file define by install

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "utility"

# Root Razor namespace
# @author Nicholas Weaver
module Razor
  # This class represents the Razor configuration. It is stored persistently in './conf/razor.conf' and editing by the user
  # @author Nicholas Weaver
  class Configuration

    include(Razor::Utility)

    # (Symbol) representing the database plugin mode to use defaults to (:mongo)
    attr_accessor :persist_mode
    attr_accessor :persist_host
    attr_accessor :persist_port
    attr_accessor :persist_timeout

    attr_accessor :admin_port
    attr_accessor :api_port
    attr_accessor :log_path

    attr_accessor :checkin_sleep
    attr_accessor :checkin_offset
    attr_accessor :register_timeout

    # init
    def initialize
      use_defaults
    end

    # Set defaults
    def use_defaults
      @persist_mode = :mongo
      @persist_host = "127.0.0.1"
      @persist_port = 27017
      @persist_timeout = 10

      @admin_port = 8017
      @api_port = 8026
      @logpath = "#{ENV['RAZOR_HOME']}/log"

      @checkin_sleep = 60
      @checkin_offset = 5
      @register_timeout = 120
    end


  end
end