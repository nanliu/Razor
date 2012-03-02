# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"

module ProjectRazor
  module Slice
    # ProjectRazor Tag Slice
    # Tag
    # @author Nicholas Weaver
    class Tag < ProjectRazor::Slice::Base

      # init
      # @param [Array] args
      def initialize(args)
        super(args)
        # Define your commands and help text
        @slice_commands = {:rules => "get_tagpolicy",
                           :default => "get_tagpolicy"}
        @slice_commands_help = {:rules => "tag [rules]"}
        @slice_name = "Tag"
      end

      # Reads the ProjectRazor config
      def get_tagpolicy
        setup_data
        if @web_command



        else
          slice_error("NotImplemented")
        end
      end

      def add_tag_rule

      end

      def delete_tag_rule

      end

      def update_tag_rule

      end
    end
  end
end