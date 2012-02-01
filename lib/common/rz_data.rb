# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_configuration"
require "rz_persist_controller"
require "yaml"

CONFIG_PATH = "#{ENV['RAZOR_HOME']}/conf/razor.conf"


# This class is the interface to all querying and saving of data
# This class uses the RzPersistController class to persist changes to the chosen database
class RZData

  attr_accessor :config
  attr_accessor :persist_controller

  # init our RZData object
  def initialize
    # We need to load from our config file
    load_config
    setup_persist
  end






  private

  def setup_persist
    @persist_controller = RZPersistController.new(@config)
  end

  # We attempt to load the file if it exists
  def load_config
    loaded_config = nil
    if File.exist?(CONFIG_PATH)
      begin
        conf_file = File.open(CONFIG_PATH)
        loaded_config = YAML.load(conf_file)
          # We catch the basic root errors
      rescue SyntaxError
        loaded_config = nil
      rescue StandardError
        loaded_config = nil
      ensure
        conf_file.close
      end
    end

    # If our object didn't load we run our config reset
    if loaded_config.is_a?(RZConfiguration)
      if loaded_config.validate_instance_vars
        @config = loaded_config
      else
        reset_config
      end
    else
      reset_config
    end
  end

  # This will create a default config object and save the razor.conf file if it doesn't exist'
  def reset_config
    # use default init
    new_conf = RZConfiguration.new

    # Very important that we only write the file if it doesn't exist as we may not be the only thread using it
    if !File.exist?(CONFIG_PATH)
      begin
        new_conf_file = File.new(CONFIG_PATH,'w+')
        new_conf_file.write(("#{new_conf_header}#{YAML.dump(new_conf)}"))
        new_conf_file.close
      rescue
        # Error writing file, add logging here later but we are ok with this to continue
      end
    end
    @config = new_conf
  end

  def new_conf_header
    "\n# This file is the main configuration for Razor\n#\n# -- this was system generated --\n#\n#\n"
  end



end