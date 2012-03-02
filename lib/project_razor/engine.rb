# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# Used for all event-driven commands and policy resolution
# @author Nicholas Weaver
class ProjectRazor::Engine
  include(ProjectRazor::Logging)

  def initialize
    @data = ProjectRazor::Data.new
  end

  # TODO policy resolve


  # TODO tag rules resolve


  def get_boot(uuid)
    logger.debug "Getting boot for uuid:#{uuid}"


    # Run tagging policies
    node_tagging(uuid)


    boot_script = ""
    boot_script << "#!ipxe\n"
    boot_script << "initrd http://192.168.99.10:8027/razor/image/mk\n"
    boot_script << "chain http://192.168.99.10:8027/razor/image/memdisk iso\n"
    boot_script
  end



  # TODO Tagging


  def node_tagging(uuid)
    node = @data.fetch_object_by_uuid(:node, uuid)
    tag_policy = @data.fetch_all_objects(:tagpolicy)

    # Iterate over each tag rule and process against node



  end




  # TODO Policy

  def node_policy


  end


  def mk_boot


  end




end
