# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"

module ProjectRazor
  module SliceUtil
    module Filtering

      def check_filter_vs_hash(filter_hash, object_hash)
        # Iterate over each key/value checking if there is a match within the object_hash level
        # if we run into a key/value that is a hash we check for a matching hash and call this same method

        filter_hash.each_pair do
          |filter_key, filter_value|

          # Find a matching key / return false if there is none
          return false if (object_key = find_key_match(filter_key, object_hash)) == nil

          # If our
          check_filter_vs_hash(filter_hash[filter_key],object_hash[object_key]) if
              filter_hash[filter_key] == Hash && object_hash[object_key].class == Hash






        end

        true
      end

      def find_key_match(filter_key, object_hash)
        object_hash.each_pair do
        |object_key, object_value|

        end
      end

    end
  end
end
