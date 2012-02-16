$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/slices"


require "data"
require "node"
require "slice_base"
require "json"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Slice
  # Razor Node Module
  # Handles all Node management
  # @author Nicholas Weaver
  class Node < Razor::Slice::Base

    def initialize(args)
      super(args)
      # Here we create a hash of the command string to the method it corresponds to for routing.
      @slice_commands = {:register => "discover_node",
                         :query => "query_node",
                         :remove => "remove_node",
                          :default => "return_all_nodes"}
      @slice_commands_help = {:register => "node register [uuid] [last state] [attributes hash(JSON STRING)]",
                              :query => "node query [one | all] (uuid) (verbose)"}
      @slice_name = "Node"
    end



    def discover_node
      @command_name = "Discovery"
      if @command_array.count == 3
        uuid = @command_array.shift
        state = @command_array.shift
        node_hash = JSON.load(@command_array.shift)
        node_hash[:@uuid] = uuid
        node_hash[:@last_state] = state

        setup_data
        new_node = insert_node(node_hash)
        slice_success if new_node.refresh_self
      else
        slice_error("MissingArguments")
      end
    end

    def insert_node(node_hash)
      @data.persist_object(Razor::Node.new(node_hash))
    end

    def query_node
      @command_name = "Query"
      if @command_array.count > 0
        query_type = @command_array.shift
        if query_type.downcase == "all" || query_type.downcase == "one"
          @command_array.each do
          |cmd|
            case cmd
              when "verbose"
                @verbose = true
                @command_array.pop
            end
          end


          case query_type
            when "all"
              return_all_nodes
              return nil
            when "one"
              if @command_array.count > 0
                return_node_by_uuid(@command_array.shift)
                return nil
              else
                slice_error("NodeUUIDNotProvided")
                return nil
              end
          end
        end
      end
      slice_error("NotImplemented")
    end

    def return_all_nodes
      setup_data
      cli_print_node(@data.fetch_all_objects(:node))
    end

    def return_node_by_uuid(uuid)
      setup_data
      node = @data.fetch_object_by_uuid(:node, uuid)
      if node != nil
        cli_print_node([node])
      else
        slice_error("NoNodeFound")
      end


    end

    def cli_print_node(node_array)


      if !@web_command
      puts "Nodes:"

      if !@verbose
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
            if !iv.to_s.start_with?("@_")
              key = iv.to_s.sub("@","")
              print "#{key}: "
              print "#{node.instance_variable_get(iv)}  ".green
            end
          end
          print "\n"
        end
      end
      else
        node_array = node_array.collect {|node| node.to_hash}
        print node_array.to_json.tr("\\", "")
      end
    end


  end
end