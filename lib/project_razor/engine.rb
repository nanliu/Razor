# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# Used for all event-driven commands and policy resolution
# @author Nicholas Weaver

require "singleton"

module ProjectRazor
  class Engine
    include(ProjectRazor::Logging)
    include(Singleton)

    # MK POLICY CHECKIN
    # Look for applicable policies
    # If found, bind, and reboot


    # BOOT POLICY CHECKIN
    # Look for applied policies
    # If found pass state receive boot script (install, boot)


    # STATE POLICY CHECKIN (Called by node install or ops & node_babysitter daemon)
    # Call-in for a state change for a node with a bound policy
    # Used to drive state changes within model and polling actions



    def mk_checkin

    end


    def boot_checkin(input_uuid)
      # Called by a node boot process

      # We sanitize the UUID to prevent compare issues
      uuid  = uuid_sanitize(input_uuid)

      logger.debug "Request for boot - uuid: #{uuid}"

      # We attempt to fetch the node object
      node = $data.fetch_object_by_uuid(:node, uuid)


      # If the node is in the DB we can check for bound policy on it
      if @node != nil
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
