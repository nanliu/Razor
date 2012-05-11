# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


module ProjectRazor
  module Error
    module Slice
      # Error class representing a request that was missing a value
      class MissingArgument < ProjectRazor::Error::Slice::Generic

        def initialize(message)
          super(message)
          @http_err = :bad_request
          @std_err = 4
        end

      end
    end
  end
end