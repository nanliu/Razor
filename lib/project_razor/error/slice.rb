# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


require_rel "slice/"


module ProjectRazor
  module Error
    module Slice
      @@error_number = 100

      # We use this to automatically generate self incrementing error numbers.
      def self.error_number
        @@error_number += 1
      end

      ProjectRazor::Error.create_class('InputError', {} ,'', 'ProjectRazor::Error::Slice::Generic')
      ProjectRazor::Error.create_class('InvalidPlugin', {} ,'', 'ProjectRazor::Error::Slice::Generic')
      ProjectRazor::Error.create_class('InvalidTemplate', {} ,'', 'ProjectRazor::Error::Slice::Generic')
      ProjectRazor::Error.create_class('MissingArgument', {} ,'', 'ProjectRazor::Error::Slice::Generic')
      ProjectRazor::Error.create_class('NotFound', {'@http_err'=>:not_found} ,'', 'ProjectRazor::Error::Slice::Generic')
    end
  end
end
