$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "configuration"
require "persist_controller"
require "yaml"
require "extlib"

CONFIG_PATH = "#{ENV['RAZOR_HOME']}/conf/razor.conf"


# Root Razor namespace
# @author Nicholas Weaver
module Razor

  # This class is the interface to all querying and saving of objects for Razor
  # @author Nicholas Weaver
  class Data

    # {Razor::Configuration} object for {Razor::Data}
    attr_accessor :config
    # {Razor::Persist::Controller} object for {Razor::Data}
    attr_accessor :persist_ctrl

    # Initializes our {Razor::Data} object
    #  Attempts to load {Razor::Configuration} and initialize {Razor::Persist::Controller}
    def initialize
      load_config
      setup_persist
    end

    # Called when work with {Razor::Data} is complete
    def teardown
      @persist_ctrl.teardown
    end

    # Fetches documents from database, converts to objects, and returns within an [Array]
    #
    # @param [Symbol] object_symbol
    # @return [Array]
    def fetch_all_objects(object_symbol)
      object_array = []
      object_hash_array = persist_ctrl.object_hash_get_all(object_symbol)
      object_hash_array.each { |object_hash| object_array << object_hash_to_object(object_hash) }
      object_array
    end

    # Fetches a document from database with a specific 'uuid', converts to an object, and returns it
    #
    # @param [Symbol] object_symbol
    # @param [String] object_uuid
    # @return [Object]
    def fetch_object_by_uuid(object_symbol, object_uuid)
      fetch_all_objects(object_symbol).each do
      |object|
        return object if object.uuid == object_uuid
      end
      nil
    end

    # Takes an {Razor::Object} and creates/persists it within the database.
    # @note If {Razor::Object} already exists it is simply updated
    #
    # @param [Symbol] object_symbol
    # @param [String] object_uuid
    # @return [Razor::Object] returned object is a copy of passed {Razor::Object} with bindings enabled for {Razor::Object#refresh_self} and {Razor::Object#update_self}
    def persist_object(object)
      persist_ctrl.object_hash_update(object.to_hash, object._collection)
      object._persist_ctrl = persist_ctrl
      object
    end

    # Removes all {Razor::Object}'s that exist in the collection name given
    #
    # @param [Symbol] object_symbol The name of the collection
    # @return [true, false]
    def delete_all_objects(object_symbol)
      persist_ctrl.object_hash_remove_all(object_symbol)
    end

    # Removes specific {Razor::Object} that exist in the collection name given
    #
    # @param [Razor::Object] object The {Razor::Object} to delete
    # @return [true, false]
    def delete_object(object)
      persist_ctrl.object_hash_remove(object.to_hash, object._collection)
    end

    # Removes specific {Razor::Object} that exist in the collection name with given 'uuid'
    #
    # @param [Symbol] object_symbol The name of the collection
    # @param [String] object_uuid The 'uuid' of the {Razor::Object}
    # @return [true, false]
    def delete_object_by_uuid(object_symbol, object_uuid)
      fetch_all_objects(object_symbol).each do
      |object|
        return persist_ctrl.object_hash_remove(object.to_hash, object_symbol) if object.uuid == object_uuid
      end
      false
    end





    # Takes a [Hash] from a {Razor::Persist:Controller} document and converts back into an {Razor::Object}
    # @api private
    # @param [Hash] object_hash The hash of the object
    # @return [Razor::Object, nil]
    def object_hash_to_object(object_hash)
      object = Object::full_const_get(object_hash["@classname"]).new(object_hash)
      object._persist_ctrl = @persist_ctrl
      object
    end

    # Initiates the {Razor::Persist::Controller} for {Razor::Data}
    # @api private
    #
    # @return [Razor::Persist::Controller, nil]
    def setup_persist
      @persist_ctrl = Razor::Persist::Controller.new(@config)
    end

    # Attempts to load the './conf/razor.conf' YAML file into @config
    # @api private
    #
    # @return [Razor::Configuration, nil]
    def load_config
      loaded_config = nil
      if File.exist?(CONFIG_PATH)
        begin
          conf_file = File.open(CONFIG_PATH)
          #noinspection RubyResolve,RubyResolve
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
      if loaded_config.is_a?(Razor::Configuration)
        if loaded_config.validate_instance_vars
          @config = loaded_config
        else
          reset_config
        end
      else
        reset_config
      end
    end

    # Creates new 'razor.conf' if one does not already exist
    # @api private
    #
    # @return [Razor::Configuration, nil]
    def reset_config
      # use default init
      new_conf = Razor::Configuration.new

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

    # Returns a header for new 'razor.conf' files
    # @api private
    #
    # @return [Razor::Configuration, nil]
    def new_conf_header
      "\n# This file is the main configuration for Razor\n#\n# -- this was system generated --\n#\n#\n"
    end

  end
end