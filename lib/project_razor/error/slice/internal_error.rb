# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


module ProjectRazor::Error::Slice
  # Error class representing a bad request such as:
  class InternelError < ProjectRazor::Error::Slice::Generic

    def initialize(message)
      super("Server Error: #{message}")
      @http_err = :internal_server_error
      @std_err = 4
    end

  end
end
