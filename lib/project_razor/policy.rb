# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

# ProjectRazor Policy class
# Used to apply ProjectRazor::Model to ProjectRazor::Node
class ProjectRazor::Policy < ProjectRazor::Object
  attr_accessor :name
  attr_accessor :model
  attr_accessor :tag_matching
  attr_accessor :policy_type

  # @param hash [Hash]
  def initialize(hash)
    super()

    @model = nil
    @property_match = {}

    @_collection = :policy
    from_hash(hash)
  end
end