# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor::Model
  # Root Model object
  # @author Nicholas Weaver
  # @abstract
  class UbuntuOneiric < ProjectRazor::Model::Base

    def initialize(hash)
      super(hash)
      @model_type = :ubuntu_oneiric
      @model_description = "Ubuntu Oneiric 11.10"
    end

    def define_values_hash
      @values_hash
    end
  end
end