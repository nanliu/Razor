# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


module ProjectRazor
  module Error
    module Slice
      # Error class representing a request that was missing a value
      class NotImplemented < ProjectRazor::Error::Slice::Generic

        def initialize(message)
          super(message)
          @http_err = :forbidden
          @std_err = 7
        end

      end
    end
  end
end