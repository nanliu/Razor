# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


# Root namespace for ProjectRazor
# @author Nicholas Weaver
module ProjectRazor::System

  # Root namespace for Systems defined in ProjectRazor for node handoff
  # @author Nicholas Weaver
  # @abstract
  class Base < ProjectRazor::Object
    attr_accessor :type
    attr_accessor :servers
    attr_accessor :description
    attr_accessor :hidden

    def initialize(hash)
      @hidden = true
      @type = :base
      @servers = []
      @description = "Base system type - not used"
      @_collection = :system
      from_hash(hash) if hash
    end


    def hand_off

    end

    def hand_off_complete?

    end



  end
end