# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

Dir.glob(ENV['RAZOR_HOME'] + '/lib/**/').each {|x| $LOAD_PATH << x} # adds Razor lib/dirs to load path


require "logger"

LOG_LEVEL = Logger::DEBUG
LOG_MAX_SIZE = 2048576
LOG_MAX_FILES = 10

# Module used for all logging. Needs to be included in any Razor class that needs logging.
# Uses Ruby Logger but overrides and instantiates one for each object that mixes in this module.
# It auto prefixes each log message with classname and method from which it was called using progname
module Razor::Logging


  # [Hash] holds the loggers for each instance that includes it
  @loggers = {}

  # Returns the logger object specific to the instance that called it
  def logger
    classname = self.class.name
    methodname = caller[0][/`([^']*)'/, 1]
    @logger ||= Razor::Logging.logger_for(classname, methodname)
    @logger.progname = "#{classname}\##{methodname}"
    @logger
  end

  # Singleton override that returns a logger for each specific instance
  class << self

    def get_log_path
      if ENV['RAZOR_LOG_PATH'] == nil
        return "#{ENV['RAZOR_HOME']}/log/razor.log"
      end
      "#{ENV['RAZOR_LOG_PATH']}/razor.log"
    end

    def get_log_level
      if ENV['RAZOR_LOG_LEVEL'] == nil
        return 3
      end
      ENV['RAZOR_LOG_LEVEL'].to_i
    end

    # Returns specific logger instance from loggers[Hash] or creates one if it doesn't exist
    def logger_for(classname, methodname)
      @loggers[classname] ||= configure_logger_for(classname, methodname)
    end

    # Creates a logger instance
    def configure_logger_for(classname, methodname)
      logger = Logger.new(get_log_path, shift_age = LOG_MAX_FILES, shift_size = LOG_MAX_SIZE)
      logger.level = get_log_level
      logger
    end
  end
end