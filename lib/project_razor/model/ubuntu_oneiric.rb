# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Model
    # Root Model object
    # @author Nicholas Weaver
    # @abstract
    class UbuntuOneiricMinimal < ProjectRazor::Model::Base

      def initialize(hash)
        super(hash)
        @model_type = :linux_deploy
        @model_description = "Ubuntu Oneiric 11.10 Minimal"
      end

    end
  end
end