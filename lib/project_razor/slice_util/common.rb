# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"

module ProjectRazor
  module SliceUtil
    module Common
      #include(ProjectRazor::Slice::Utility::Filtering)


      # Gets a selection of objects for slice
      # @param noun [String] name of the object for logging
      # @param collection [Symbol] collection for object

      def get_object(noun, collection)
        logger.debug "Query #{nodes} called"

        # Check if REST-driven request
        if @web_command

          # Get request filter JSON string
          @filter_json_string = @command_array.shift

          # Check if we were passed a filter string
          # TODO - make this more than just a uuid filter
          if @filter_json_string != "{}" && @filter_json_string != nil
            @command = "query_with_filter"
            begin
              # Render our JSON to a Hash
              filter = JSON.parse(@filter_json_string)
              logger.debug "Filter: #{filter["uuid"]}"

              # Check is filter contains a valid field, in this case only uuid is implemented right now
              if filter["uuid"] != nil
                # Get objects based on filter
                return_object_using_filter(filter)
              else
                # Return error signifying filter is invalid
                slice_error("InvalidFilter")
              end
            rescue StandardError => e
              # We caught an error / likely JSON. We return the error text as a Slice error.
              slice_error(e.message)
            end
          else
            @command = "query_all"
            return_objects
          end
          # Is CLI driven
        else
          return_objects
        end
      end

      # Return objects using a filter
      # @param filter [Hash] contains key/values used for filtering
      def return_object_using_filter(filter)


      end

      # Return all objects (no filtering)
      def return_objects

      end




    end
  end
end
