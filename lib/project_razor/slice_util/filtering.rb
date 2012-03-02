# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

module ProjectRazor
  module SliceUtil
    module Filtering

      def check_filter_vs_hash(filter_hash, object_hash)
        # Iterate over each key/value checking if there is a match within the object_hash level
        # if we run into a key/value that is a hash we check for a matching hash and call this same method

        filter_hash.each_key do
          |filter_key|

          # Find a matching key / return false if there is none
          object_key = find_key_match(filter_key, object_hash)
          return false if object_key == nil

          # If our keys match and the values are Hashes then iterate again catching the return and
          # passing if it is False
          if filter_hash[filter_key] == Hash && object_hash[object_key].class == Hash
            return false if !check_filter_vs_hash(filter_hash[filter_key],object_hash[object_key])
          end

          # Eval if our keys (one of which isn't a Hash) match
          # We accept either exact or Regex match
          if filter_hash[filter_key] != object_hash[object_key] &&
              Regexp.new(filter_hash[filter_key]) != object_hash[object_key]
            return false
          end
        end

        true
      end

      def find_key_match(filter_key, object_hash)
        object_hash.each_key do
        |object_key|
          return object_key if filter_key == object_key
        end
        nil
      end

    end
  end
end
