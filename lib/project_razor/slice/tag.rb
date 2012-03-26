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
        @slice_commands = {:rule => "rule_call",
                           :get => "get_tag",
                           :add => "add_tag",
                           :remove => "remove_tag",
                           :matcher => "matcher_call",
                           :default => "get_tag_rule"}
        @slice_commands_help = {:rules => "tag [rules]",
                                :get => "tag ".red + "{get [rule|matcher]}".blue,
                                :add => "tag add ".red + "[rule|matcher]".blue,
                                :remove => "tag remove ".red + "[rule|matcher] (uuid)".blue,}
        @slice_name = "Tag"
      end


      def rule_call
        @command_query_string = @command_array.shift

        case @command_query_string

          when "add"
            add_tag_rule

          when "remove"
            remove_tag_rule


          else
            if @command_query_string != "{}" && @command_query_string != nil


              if (/^\{.*\}$/ =~ @command_query_string) != nil
                @command_array.unshift(@command_query_string)
                get_tag_rule

              else

                @command = "get_tag_rule"
                tag_rule = get_tag_rule_by_uuid(@command_query_string)
                slice_success(tag_rule.to_hash, false) unless !tag_rule

              end

            else

              # get all rules
              get_tag_rule

            end


        end


      end




      def get_tag_rule
        setup_data
        if @web_command
          print_rule get_object("tag_rule", :tag)
        else
          slice_error("NotImplemented", false)
        end
      end

      def add_tag_rule
        @command = "remove_tag_rule"
        json_string = @command_array.shift
        if json_string != "{}" && json_string != nil
          begin
            post_hash = JSON.parse(json_string)
            if post_hash["@name"] != nil && post_hash["@tag"] != nil && post_hash["@tag_matchers"] != nil
              new_tag_rule = ProjectRazor::Tagging::TagRule.new(post_hash)
              setup_data
              if @data.persist_object(new_tag_rule) != nil
                print_rule new_tag_rule
              else
                slice_error("CouldNotCreateTagRule", false)
              end
            else
              slice_error("MissingProperties", false)
            end
          rescue => e
            slice_error(e.message, false)
          end

        else
          slice_error("MissingAttributes", false)
        end
      end

      def remove_tag_rule
        @command = "remove_tag_rule"
        # First make sure we have a valid rule
        tag_rule = get_tag_rule_by_uuid(@command_array.shift)
        return if !tag_rule
        setup_data
        if @data.delete_object_by_uuid(:tag, tag_rule.uuid)
          slice_success("TagRuleDeleted", false)
        else
          slice_error("TagRuleCouldNotBeDeleted", false)
        end

      end


      def print_rule(rule_array)
        if rule_array.respond_to?(:each)
          rule_array = rule_array.collect { |rule| rule.to_hash }
          slice_success(rule_array, false)
        else
          slice_success(rule_array.to_hash, false)
        end

      end




      def matcher_call
        @command_query_string = @command_array.shift
        case @command_query_string

          when "add"
            add_tag_matcher
          when "remove"
            remove_tag_matcher
          else
            @command = "get_tag_matcher"
            tag_rule = get_tag_rule_by_uuid(@command_query_string)
            slice_success(tag_rule.to_hash, false) unless !tag_rule
        end
      end

      def add_tag_matcher
        @command = "add_tag_matcher"
        # First make sure we have a valid rule
        tag_rule = get_tag_rule_by_uuid(@command_array.shift)
        return if !tag_rule


        begin
          json_string = @command_array.shift
          if json_string != nil && (json_string =~ /^\{.*\}$/) != nil && json_string != ''
            tag_matcher = ProjectRazor::Tagging::TagMatcher.new(JSON.parse(json_string))
            if tag_rule.add_tag_matcher(tag_matcher.key,tag_matcher.value,tag_matcher.compare,tag_matcher.inverse)
              if tag_rule.update_self
                slice_success(tag_rule.to_hash, false)
              else
                slice_error("CouldNotUpdateTagRule", false)
              end
            else
              slice_error("CouldNotAddTagMatcherToRule", false)
            end
          else
            slice_error("MissingTagMatcherProperties", false)
          end
        rescue => e
          logger.error e.message
          slice_error(e.message, false)
        end
      end


      def remove_tag_matcher
        @command = "add_tag_matcher"
        # First make sure we have a valid rule
        tag_rule = get_tag_rule_by_uuid(@command_array.shift)
        return if !tag_rule


        begin
          uuid = @command_array.shift
          if uuid != nil && (uuid =~ /^\{.*\}$/) == nil && uuid != ''
            if tag_rule.remove_tag_matcher(uuid)
              slice_success(tag_rule.to_hash, false)
            else
              slice_error("TagMatcherNotFound", false)
            end
          else
            slice_error("InvalidTagMatcherUUID", false)
          end
        rescue => e
          logger.error e.message
          slice_error(e.message, false)
        end
      end

      def get_tag_rule_by_uuid(uuid)
        if uuid != nil && (uuid =~ /^\{.*\}$/) == nil && uuid != ''
          @command_array.unshift('{"@uuid":"' + uuid +'"}')
          tag_rules = get_object("tag_rule", :tag)
          tag_rules.each do
          |tag_rule|
            if tag_rule.uuid == uuid
              return tag_rule
            end
          end
          slice_success("TagRuleNotFound", false)
          false
        else
          slice_error("NoTagRuleUUIDProvided", false)
          false
        end
      end
    end
  end
end