# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# Used for all event-driven commands and policy resolution
# @author Nicholas Weaver

require "singleton"

module ProjectRazor
  class Engine
    include(ProjectRazor::Logging)
    include(Singleton)
    include(Logging)

    # MK POLICY CHECKIN
    # Look for applicable policies
    # If found, bind, and reboot


    # BOOT POLICY CHECKIN
    # Look for applied policies
    # If found pass state receive boot script (install, boot)


    # STATE POLICY CHECKIN (Called by node install or ops & node_babysitter daemon)
    # Call-in for a state change for a node with a bound policy
    # Used to drive state changes within model and polling actions

    #####################
    ##### MK Section ####
    #####################

    def mk_checkin(input_uuid, last_state)
      old_timestamp = 0 # we set this early in case a timestamp field is nil

      uuid  = uuid_sanitize(input_uuid)
      # We attempt to fetch the node object
      node = $data.fetch_object_by_uuid(:node, uuid)

      # Check to see if node is known
      if node

        # Node is known we need to update timestamp
        old_timestamp = node.timestamp unless node.timestamp == nil
        node.last_state = last_state    # We update last_state for the node
        node.timestamp = Time.now.to_i  # We update timestamp for the node
        unless node.update_self # Update node catching if it fails
          logger.error "Node #{node.uuid} checkin failed"
        end
        logger.debug "Node #{node.uuid} checkin accepted"

        # Check for a node action override
        forced_action = checkin_action_override(uuid)
        # Return the forced command if it exists
        logger.debug "Forced action for Node #{node.uuid} found #{forced_action.to_s}" if forced_action
        return mk_command(forced_action,{}) if forced_action


        # Check to see if the time span since the last node contact
        # is greater than our register_timeout
        if (node.timestamp - old_timestamp) > $data.config.register_timeout
          # Our node hasn't talked to the server within an acceptable time frame
          # we will request a re-register to refresh details about the node
          logger.debug "Asking Node #{node.uuid} to re-register as we haven't talked to him in #{(node.timestamp - old_timestamp)} seconds"
          return mk_command(:register,{})
        end

        # Check to see if there is a bound policy
        # If there is we will call the mk_call method common to all policies
        # A bound policy means the node will never evaluate a policy rule
        # So for safety's sake - we set an extra flag (bound_policy_flag) which
        # prevents the policy eval below to run
        @bound_policy_flag = true



        # Evaluate node vs policy rules to see if a policy needs to be bound
        unless @bound_policy_flag

        end


        # If we got to this point we just need to acknowledge the checkin
        mk_command(:acknowledge,{})

      else
        # Never seen this node - we tell it to checkin
        logger.debug "Unknown Node #{node.uuid}, asking to register"
        mk_command(:register,{})
      end
    end


    def mk_check_bound_policy

    end


    def mk_eval_vs_policy_rule

    end


    # Used to override per-node checkin behavior for testing
    def checkin_action_override(uuid)
      checkin_file = "#{$razor_root}/conf/checkin_action.yaml"

      return nil unless File.exist?(checkin_file) # skip is file doesn't exist'
      f = File.open(checkin_file,"r")
      checkin_actions = YAML.load(f)
      checkin_actions[uuid] # return value for key matching uuid or nil if none
    end


    def mk_command(command_name, command_param)
      command_response = {}
      command_response['command_name'] = command_name
      command_response['command_param'] = command_param
      command_response
    end


    #######################
    ##### Boot Section ####
    #######################

    def boot_checkin(input_uuid)
      # Called by a node boot process

      # We sanitize the UUID to prevent compare issues
      uuid  = uuid_sanitize(input_uuid)

      logger.debug "Request for boot - uuid: #{uuid}"

      # We attempt to fetch the node object
      node = $data.fetch_object_by_uuid(:node, uuid)


      # If the node is in the DB we can check for bound policy on it
      if node != nil
        # Node is in DB, lets check for policy
        logger.debug "Node identified - uuid: #{uuid}"
        bound_policy = find_bound_policy(node)

        # If there is a bound policy we pass it the node to a common
        # method call from a boot
        if bound_policy

          logger.debug "Active policy found (#{bound_policy.name}) - uuid: #{uuid}"
          bound_policy.boot_call(@node)
        else

          # There is not bound policy so we boot the MK
          logger.debug "No active policy found - uuid: #{uuid}"
          default_mk_boot(uuid)
        end
      else

        # Node isn't in DB, we boot it into the MK
        # This is a default behavior
        logger.debug "Node unknown - uuid: #{uuid}"
        default_mk_boot(uuid)
      end

    end


    def state_checkin

    end


    def find_bound_policy(node)
      bound_policies = $data.fetch_all_objects(:bound_policy)
      bound_policies.each do
        |bp|
        # If we find a bound policy we return it
        return bp.policy_bound if uuid_sanitize(bp.uuid) == uuid_sanitize(node.uuid)
      end
      # Otherwise we return false indicating we have no policy
      false
    end




    def default_mk_boot(uuid)
      logger.debug "Responding with MK Boot - uuid: #{uuid}"
      default = ProjectRazor::Policy::BootMK.new
      default.get_boot_script
    end



    def find_policy(node)
      # Get all active policies
      node_policies = $data.fetch_all_objects(:policy)

      node_policies.each do
        |np|
        return np if check_tags(node.tags,np.tags)
      end
      false
    end


    def check_tags(node_tags,policy_tags)
      policy_tags.each do
        |pt|
        return false unless node_tags.include?(pt)
      end
      true
    end


    def node_tags(node)
      node.attributes_hash
      tag_policies = $data.fetch_all_objects(:tag)

      tags = []
      tag_policies.each do
      |tag_pol|
        if tag_pol.check_tag_rule(node.attributes_hash)
          tags << tag_pol.tag
        end
      end
      tags
    end


    ######## Boot init section






    ########




    def uuid_sanitize(uuid)
      uuid = uuid.gsub(/[:;,]/,"")
      uuid = uuid.upcase
    end
  end
end
