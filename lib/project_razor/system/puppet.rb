# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# Our puppet plugin which contains the agent & device proxy classes used for hand off
require "project_razor/system/plugin/puppet"

# Root namespace for ProjectRazor
# @author Nicholas Weaver
module ProjectRazor::System

  # Root namespace for Puppet System type defined in ProjectRazor for node handoff
  # @author Nicholas Weaver
  class Puppet < ProjectRazor::System::Base

    def initialize(hash)
      super(hash)

      @type = :puppet
      @description = "PuppetLabs PuppetMaster"
      @hidden = false
      from_hash(hash) if hash
    end
  end
end