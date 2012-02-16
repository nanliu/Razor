require "logger"

# TODO link to configuration for Log Level
# TODO link to configuration for Log path
LOG_FILE = "#{ENV['RAZOR_HOME']}/log/razor.log"
LOG_LEVEL = Logger::DEBUG
LOG_ROTATION = "daily"

# Module used for all logging. Needs to be included in any Razor class that needs logging.
# Uses Ruby Logger but overrides and instantiates one for each object that mixes in this module.
# It auto prefixes each log message with classname and method from which it was called using progname
module Razor::Logging



  # [Hash] holds the loggers for each instance that includes it
  @loggers = {}

  # Returns the logger object specific to the instance that called it
  def logger
    #TODO make logging to STDOUT flip-able
    threadid = Thread.current.object_id
    classname = self.class.name
    methodname = caller[0][/`([^']*)'/, 1]
    @logger ||= Razor::Logging.logger_for(classname, methodname)
    @logger.progname = "#{classname}\##{methodname}"
    @logger
  end

  # Singleton override that returns a logger for each specific instance
  class << self
    # Returns specific logger instance from loggers[Hash] or creates one if it doesn't exist
    def logger_for(classname, methodname)
      @loggers[classname] ||= configure_logger_for(classname, methodname)
    end

    # Creates a logger instance
    def configure_logger_for(classname, methodname)
      logger = Logger.new LOG_FILE, LOG_ROTATION
      logger.level = LOG_LEVEL
      logger
    end
  end
end