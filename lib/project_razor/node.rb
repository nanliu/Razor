# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


# Root ProjectRazor::Node namespace
# @author Nicholas Weaver
class ProjectRazor::Node < ProjectRazor::Object
  attr_accessor :name
  attr_accessor :attributes_hash
  attr_accessor :timestamp
  attr_accessor :last_state
  attr_accessor :current_state
  attr_accessor :next_state
  attr_accessor :tags

  # init
  # @param hash [Hash]
  def initialize(hash)
    super()
    @_collection = :node
    @attributes_hash = {}
    from_hash(hash)
  end
end