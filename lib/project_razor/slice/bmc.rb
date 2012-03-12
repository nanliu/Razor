# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "yaml"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice Bmc
    # Used for all BMC/IPMI logic
    # @author Tom McSweeney
    class Bmc < ProjectRazor::Slice::Base
      include(ProjectRazor::Logging)
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:register => "register_bmc",
                           :default => "query_bmc"}
        @slice_commands_help = {:register => "bmc register (JSON STRING)",
                                :default => "bmc (JSON STRING)"}
        @slice_name = "Bmc"
      end


      # Registers BMC NIC
      def register_bmc
        logger.debug "Register bmc called"
        @command_name = "register_bmc"
        if @web_command
          @command_query_string = @command_array.shift
          if @command_query_string == "{}"
            logger.error "Missing bmc details"
            slice_error("MissingDetails")
          else
            details = JSON.parse(@command_query_string)

            if details['@uuid'] != nil && details['@mac'] != nil && details['@ip'] != nil

              logger.debug "bmc: #{details['@mac']} #{details['@ip']}"
              details['@timestamp'] = Time.now.to_i
              new_bmc = insert_bmc(details)

              if new_bmc.refresh_self
                slice_success(new_bmc.to_hash, true)
              else
                logger.error "Could not register bmc"
                slice_error("CouldNotRegister", true)
              end
            else
              logger.error "Incomplete bmc details"
              slice_error("IncompleteDetails",true)
            end
          end
        end
      end

      # Inserts bmc using hash
      # @param [Hash] bmc_hash
      # @return [ProjectRazor::Bmc]
      def insert_bmc(bmc_hash)
        setup_data
        existing_bmc = @data.fetch_object_by_uuid(:bmc, bmc_hash['@uuid'])
        if existing_bmc != nil
          existing_bmc.last_state = bmc_hash['@last_state']
          existing_bmc.attributes_hash = bmc_hash['@attributes_hash']
          existing_bmc.update_self
          existing_bmc
        else
          @data.persist_object(ProjectRazor::Bmc.new(bmc_hash))
        end
      end

      def query_bmc
        print_bmc get_object("bmc", :bmc)
      end

      # Handles printing of bmc details to CLI or REST
      # @param [Hash] bmc_array
      def print_bmc(bmc_array)
        unless @web_command
          puts "BMC:"

          unless @verbose
            bmc_array.each do
            |bmc|
              print "\tmac: "
              print "#{bmc.mac}  ".green
              print "last state: "
              print "#{bmc.ip}   ".green
              print "\n"
            end
          else
            bmc_array.each do
            |bmc|
              bmc.instance_variables.each do
              |iv|
                unless iv.to_s.start_with?("@_")
                  key = iv.to_s.sub("@", "")
                  print "#{key}: "
                  print "#{bmc.instance_variable_get(iv)}  ".green
                end
              end
              print "\n"
            end
          end
        else
          bmc_array = bmc_array.collect { |bmc| bmc.to_hash }
          slice_success(bmc_array,false)
        end
      end

    end
  end
end
