# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


module ProjectRazor::Error::Slice
  # Error class representing a bad request such as:
  # * missing information
  class BadRequest < ProjectRazor::Error::Slice::Generic
    def initialize(message)
      super("Bad request: #{message}")
      @http_err = :bad_request
      @std_err = 4
    end
  end

  class MissingArgument < ProjectRazor::Error::Slice::BadRequest
    def initialize(message)
      super("missing argument #{message}")
    end
  end

  class InvalidPlugin < ProjectRazor::Error::Slice::BadRequest
    def initialize(message)
      super("invalid plugin #{message}")
    end
  end

  class InvalidTemplate < ProjectRazor::Error::Slice::BadRequest
    def initialize(message)
      super("invalid template #{message}")
    end
  end
end
