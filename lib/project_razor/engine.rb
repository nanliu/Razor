# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# Used for all event-driven commands and policy resolution
# @author Nicholas Weaver

require "singleton"

module ProjectRazor
  class Engine
    include(ProjectRazor::Logging)
    include(Singleton)

    # TODO policy resolve


    # TODO tag rules resolve


    def boot_call(uuid)
      @uuid  = uuid_sanitize(uuid)
      logger.debug "Request for boot - uuid: #{@uuid}"
      @node = $data.fetch_object_by_uuid(:node, @uuid)

      if @node != nil
        # Node is in DB, lets check for policy
        logger.debug "Node identified - uuid: #{@uuid}"
        default_mk_boot
      else
        # Node isn't in DB, we choose default BootMK
        logger.debug "Node unknown - uuid: #{@uuid}"
        default_mk_boot
      end
    end

    def default_mk_boot
      logger.debug "Responding with MK Boot - uuid: #{@uuid}"
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

    def uuid_sanitize(uuid)
      uuid = uuid.gsub(/[:;,]/,"")
      uuid = uuid.upcase
    end
  end
end
