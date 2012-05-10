# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


module ProjectRazor::Error::Slice
  # Error class representing a bad request such as:
  # * missing information
  class NotFound < ProjectRazor::Error::Slice::Generic

    def initialize(message)
      super("Not Found: #{message}")
      @http_err = :not_found
      @std_err = 3
    end

  end
end
