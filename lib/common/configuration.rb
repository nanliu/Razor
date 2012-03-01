# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

Dir.glob(ENV['RAZOR_HOME'] + '/lib/**/').each {|x| $LOAD_PATH << x} # adds Razor lib/dirs to load path


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
    attr_accessor :imagesvc_port

    attr_accessor :checkin_sleep
    attr_accessor :checkin_offset
    attr_accessor :register_timeout

    attr_accessor :base_mk

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

      @admin_port = 8025
      @api_port = 8026
      @imagesvc_port = 8027

      @checkin_sleep = 60
      @checkin_offset = 5
      @register_timeout = 120

      @base_mk = "rz_mk_dev-image.0.1.3.0.iso"
      @razor_ip = "127.0.0.1"

    end


  end
end