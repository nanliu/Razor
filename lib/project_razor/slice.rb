# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "require_all"
require "project_razor/slice_util/common"
require_rel "slice/"

module ProjectRazor
  module Error
    module Slice
      # To change this template use File | Settings | File Templates.
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
