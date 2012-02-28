$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"


require "data"
require "node"
require "slice_base"
require "json"
require "logging"
require "yaml"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Node Module
  # Handles all Node management
  # @author Nicholas Weaver
  class Node < Razor::Slice::Base

    # TODO add filtering by any value
    # TODO add filtering by AND | OR
    # TODO add REGEX to filtering
    # TODO finish logging
    # TODO fill out comments


    # Initializes Razor::Slice::Node including #slice_commands, #slice_commands_help, & #slice_name
    # @param [Array] args
    def initialize(args)
      super(args)
      # Here we create a hash of the command string to the method it corresponds to for routing.
      @slice_commands = {:register => "register_node",
                         :checkin => "checkin_node",
                         :remove => "remove_node",
                         :default => "query_node"}
      @slice_commands_help = {:register => "node register (JSON STRING)",
                              :default => "node (JSON STRING)"}
      @slice_name = "Node"
    end

    # Runs a node checkin returning appropriate command
    def checkin_node
      # TODO this needs to be wired to the *future* Razor::Engine

      f = File.open("#{ENV['RAZOR_HOME']}/conf/checkin_action.yaml","r")
      checkin_actions = YAML.load(f)


      # ensure there are at least uuid & state

      @command_query_string = @command_array.shift
      if @command_query_string != "{}" && @command_query_string != nil



        begin
          params = JSON.parse(@command_query_string)
          if params["uuid"] != nil && params["last_state"] != nil

            node = node_exist?(params["uuid"])
            if node
              logger.debug "Node exists"
              old_timestamp = node.timestamp
              old_timestamp = 0 if old_timestamp == nil
              node.last_state = params["last_state"]
              node.timestamp = Time.now.to_i
              node.update_self

              forced_action = checkin_actions[params["uuid"]]
              if forced_action != nil
                logger.debug "Forcing action: #{forced_action.to_s}"
                slice_success(get_command(forced_action, {}))
              else

                setup_data
                if (node.timestamp - old_timestamp) > @data.config.register_timeout
                  logger.debug "Checkin acknowledged: #{forced_action.to_s}"
                  slice_success(get_command(:register, {}))
                else
                  logger.debug "Checkin acknowledged: #{forced_action.to_s}"
                  slice_success(get_command(:acknowledge, {}))
                end
              end
            else
              # Don't have record of this node
              logger.debug "No record of this node"

              slice_success(command_response)
            end

          else
            slice_error("InvalidOrMissingParameters")
          end
        rescue StandardError => e
          slice_error(e.message)
        end
      else
        slice_error("MissingRequiredParameters(uuid, state)")
      end
    end

    # Builds a command for a checkin
    # @param [String] command_name
    # @param [Hash] command_param
    # @return [Hash]
    def get_command(command_name, command_param)
      command_response = {}
      command_response['command_name'] = command_name
      command_response['command_param'] = command_param
      command_response
    end

    # Checks if node exists in DB returns node object or false
    # @param [String] uuid
    # @return [Razor::Node, false]
    def node_exist?(uuid)
      setup_data
      node = @data.fetch_object_by_uuid(:node, uuid)
      return node if node.uuid == uuid
      false
    end

    # Registers node
    def register_node
      logger.debug "Register node called"
      @command_name = "register_node"

      if @web_command
        @command_query_string = @command_array.shift
        if @command_query_string == "{}"
          logger.error "Missing node details"
          slice_error("MissingDetails")
        else
          details = JSON.parse(@command_query_string)

          if details['@uuid'] != nil && details['@last_state'] != nil && details['@attributes_hash'] != nil

            logger.debug "node: #{details['@uuid']} #{details['@_last_state']}"
            details['@timestamp'] = Time.now.to_i
            new_node = insert_node(details)

            if new_node.refresh_self
              slice_success(new_node.to_hash)
            else
              logger.error "Could not register node"
              slice_error("CouldNotRegister")
            end
          else
            logger.error "Incomplete node details"
            slice_error("IncompleteDetails")
          end
        end
      end
    end

    # Removes node
    def remove_node
      slice_error("NotImplemented")
    end

    # Inserts node using hash
    # @param [Hash] node_hash
    # @return [Razor::Node]
    def insert_node(node_hash)
      setup_data
      existing_node = @data.fetch_object_by_uuid(:node, node_hash['@uuid'])
      if existing_node != nil
        existing_node.last_state = node_hash['@last_state']
        existing_node.attributes_hash = node_hash['@attributes_hash']
        existing_node.update_self
        existing_node
      end
        @data.persist_object(Razor::Node.new(node_hash))
      end
    end

    # Queries [Array] of nodes matching filter if supplied in command
    def query_node
      logger.debug "Query nodes called"

      if @web_command
        @command_query_string = @command_array.shift
        if @command_query_string != "{}" && @command_query_string != nil
          @command = "query_with_filter"
          begin
            logger.debug "***#{@command_query_string}"
            filter = JSON.parse(@command_query_string)

            logger.debug "Filter: #{filter.inspect}"
            logger.debug "Filter: #{filter["uuid"]}"
            if filter["uuid"] != nil
              return_node_by_uuid(filter["uuid"])
            else
              slice_error("InvalidFilter")
            end
          rescue StandardError => e
            slice_error(e.message)
          end
        else
          @command = "query_all"
          return_all_nodes
        end
      else
        return_all_nodes
      end
    end

    # Returns all nodes in DB from slice
    def return_all_nodes
      setup_data
      print_node(@data.fetch_all_objects(:node))
    end

    # Return node matching uuid from Slice
    # @param [String] uuid
    def return_node_by_uuid(uuid)
      setup_data
      node = @data.fetch_object_by_uuid(:node, uuid)
      node = [] if node == nil
      print_node([node])
    end

    # Handles printing of node details to CLI or REST
    # @param [Hash] node_array
    def print_node(node_array)
      unless @web_command
        puts "Nodes:"

        unless @verbose
          node_array.each do
          |node|
            print "\tuuid: "
            print "#{node.uuid}  ".green
            print "last state: "
            print "#{node.last_state}  ".green
            print "name: " unless node.name == nil
            print "#{node.name}  ".green unless node.name == nil
            print "\n"
          end
        else
          node_array.each do
          |node|
            node.instance_variables.each do
            |iv|
              unless iv.to_s.start_with?("@_")
                key = iv.to_s.sub("@", "")
                print "#{key}: "
                print "#{node.instance_variable_get(iv)}  ".green
              end
            end
            print "\n"
          end
        end
      else
        node_array = node_array.collect { |node| node.to_hash }
        slice_success node_array
      end
    end


  end
end