
# Root ProjectRazor namespace
module ProjectRazor
  module Slice

    # ProjectRazor Slice Tag
    # Used for managing the tagging system
    class Tag < ProjectRazor::Slice::Base
      # Initializes ProjectRazor::Slice::Tag
      # @param [Array] args
      def initialize(args)
        super(args)
        @hidden = false
        @new_slice_style = true
        @slice_commands = {:add => "add_tagrule",
                           :get => "get_tagrule",
                           :update => "update_tagrule",
                           :remove => "remove_tagrule",
                           :matcher => {
                               :add => "add_matcher",
                               :get => "get_matcher",
                               :update => "update_matcher",
                               :remove => "remove_matcher",
                               :default => :get,
                               :else => :get
                           },
                           :default => :get,
                           :else => :get,
                           ["--help", "-h"] => "tag_help" }
        @slice_name = "Tag"
      end

      def tag_help
        puts "Tag Slice:".red
        puts "Used to view, create, update, and remove Tag Rules and Tag Matchers.".red
        puts "Tag commands:".yellow
        puts "\trazor tag [get] [--all]                         " + "View all Tag Rules/Matchers".yellow
        puts "\trazor tag [matcher] [get] (UUID)                " + "View a specific Tag Rule/Matcher".yellow
        puts "\trazor tag [matcher] add (options...)            " + "Create a new Tag Rule/Matcher".yellow
        puts "\trazor tag [matcher] update (UUID) (options...)  " + "Update an existing Tag Rule/Matcher".yellow
        puts "\trazor tag [matcher] remove (UUID)               " + "Remove an existing Tag Rule/Matcher".yellow
        puts "\trazor tag remove --all                          " + "Remove all existing Tag Rules".yellow
        puts "\trazor tag --help|-h                             " + "Display this screen".yellow
      end

      def get_tagrule
        @command = :get_tagrule
        @command_help_text << "Description: Gets the Properties Associated with one or more Tag Rules\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :get)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tagrule_uuid, options = parse_and_validate_options(option_items, "razor tag get [UUID] [option]", :require_all)
        if !@web_command
          tagrule_uuid = @command_array.shift
        end
        includes_uuid = true if tagrule_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        if includes_uuid
          # get the details for a specific tag
          get_tagrule_with_uuid(tagrule_uuid)
        else
          # get a summary view of all tags; will end up here
          # if the option chosen is the :all option (or if nothing but the
          # 'get' subcommand was specified as this is the default action)
          get_all_tagrules
        end
      end

      def add_tagrule
        @command = :add_tagrule
        @command_help_text << "Description: Used to add a new Tag Rule to Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :add)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "razor tag add (options...)", :require_all)
        includes_uuid = true if tmp
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        # create a new tagrule using the options that were passed into this subcommand,
        # then persist the tagrule object
        tagrule = ProjectRazor::Tagging::TagRule.new({"@name" => options[:name], "@tag" => options[:tag]})
        raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Tag Rule") unless tagrule
        setup_data
        @data.persist_object(tagrule)
        print_object_array([tagrule], "", :success_type => :created)
      end

      def update_tagrule
        @command = :update_policy
        @command_help_text << "Description: Used to update an existing Tag Rule\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :update)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tagrule_uuid, options = parse_and_validate_options(option_items, "razor tag update UUID (options...)", :require_one)
        if !@web_command
          tagrule_uuid = @command_array.shift
        end
        includes_uuid = true if tagrule_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)

        # get the tagfule to update
        tagrule = get_object("tagrule_with_uuid", :tag, tagrule_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tagrule_uuid}]" unless tagrule
        tagrule.name = options[:name]
        tagrule.tag = options[:tag]
        raise ProjectRazor::Error::Slice::CouldNotUpdate, "Could not update Tag Rule [#{tagrule.uuid}]" unless tagrule.update_self
        print_object_array [tagrule], "", :success_type => :updated
      end

      def remove_tagrule
        @command = :remove_tagrule
        @command_help_text << "Description: remove one Tag Rule (or all Tag Rules) from the system\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :remove)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tagrule_uuid, options = parse_and_validate_options(option_items, "razor tag remove (UUID)|(--all)", :require_all)
        if !@web_command
          tagrule_uuid = @command_array.shift
        end
        includes_uuid = true if tagrule_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        # and then invoke the right method (based on usage)
        # selected_option = options.select { |k, v| v }.keys[0].to_s
        if options[:all]
          # remove all Policies from the system
          remove_all_tagrules
        elsif includes_uuid
          # remove a specific Policy (by UUID)
          remove_tagrule_with_uuid(tagrule_uuid)
        else
          # if get to here, no UUID was specified and the '--all' option was
          # no included, so raise an error and exit
          raise ProjectRazor::Error::Slice::MissingArgument, "Must provide a UUID for the tag rule to remove (or select the '--all' option)"
        end
      end

      def get_all_tagrules
        # Get all tag rules and print/return
        print_object_array(get_object("tagrules", :tag), "Tag Rules",
                           :style => :table, :success_type => :generic)
      end

      def get_tagrule_with_uuid(tagrule_uuid)
        tagrule = get_object("tagrule_with_uuid", :tag, tagrule_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tagrule_uuid}]" unless tagrule
        print_object_array [tagrule], "", :success_type => :generic
      end

      def remove_all_tagrules
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Tag Rules" unless @data.delete_all_objects(:tag)
        slice_success("All Tag Rules removed", :success_type => :removed)
      end

      def remove_tagrule_with_uuid(tagrule_uuid)
        tagrule = get_object("tagrule_with_uuid", :tag, tagrule_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tagrule_uuid}]" unless tagrule
        setup_data
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Tag Rule [#{tagrule.uuid}]" unless @data.delete_object(tagrule)
        slice_success("Tag Rule [#{tagrule.uuid}] removed", :success_type => :removed)
      end

      # Tag Matcher
      #

      def find_matcher(matcher_uuid)
        found_matcher = []
        setup_data
        @data.fetch_all_objects(:tag).each do
        |tr|
          tr.tag_matchers.each do
          |matcher|
            found_matcher << [matcher, tr] if matcher.uuid.scan(matcher_uuid).count > 0
          end
        end
        found_matcher.count == 1 ? found_matcher.first : nil
      end

      def get_matcher
        @command = :get_matcher
        @command_help_text << "Description: gets the properties associated with a Tag Matcher\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = { }
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        matcher_uuid, options = parse_and_validate_options(option_items, "razor tag matcher get (UUID)", :require_all)
        if !@web_command
          matcher_uuid = @command_array.shift
        end
        includes_uuid = true if matcher_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        raise ProjectRazor::Error::Slice::MissingArgument, "Must provide a Tag Matcher UUID" unless validate_arg(matcher_uuid)
        matcher, tagrule = find_matcher(matcher_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag Matcher with UUID [#{matcher_uuid}]" unless matcher
        print_object_array [matcher], "", :success_type => :generic
      end

      def add_matcher
        @command = :add_policy
        @command_help_text << "Description: Used to add a new Tag Matcher to Razor\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :add_matcher)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        tmp, options = parse_and_validate_options(option_items, "razor tag matcher add (options...)", :require_all)
        includes_uuid = true if tmp
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        tagrule_uuid = options[:tagrule_uuid]
        key = options[:key]
        compare = options[:compare]
        value = options[:value]
        inverse = (options[:inverse] ? "true" : "false")

        # check the values that were passed in
        tagrule = get_object("tagrule_with_uuid", :tag, tagrule_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Tag Rule with UUID: [#{tagrule_uuid}]" unless tagrule
        raise ProjectRazor::Error::Slice::MissingArgument, "Option for --compare must be [equal|like]" unless compare == "equal" || compare == "like"
        matcher = tagrule.add_tag_matcher(:key => key, :compare => compare, :value => value, :inverse => inverse)
        raise ProjectRazor::Error::Slice::CouldNotCreate, "Could not create tag matcher" unless matcher
        raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not create Tag Matcher") unless tagrule.update_self
        print_object_array([matcher], "Tag Matcher created:", :success_type => :created)
      end

      def update_matcher
        @command = :update_matcher
        @command_help_text << "Description: Used to update an existing Tag Matcher\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = load_option_items(:command => :update_matcher)
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        matcher_uuid, options = parse_and_validate_options(option_items, "razor policy update UUID (options...)", :require_one)
        if !@web_command
          matcher_uuid = @command_array.shift
        end
        includes_uuid = true if matcher_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, false)
        tagrule_uuid = options[:tagrule_uuid]
        key = options[:key]
        compare = options[:compare_method]
        value = options[:value]
        invert = options[:invert]

        # check the values that were passed in
        matcher, tagrule = find_matcher(matcher_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag Matcher with UUID [#{matcher_uuid}]" unless matcher
        raise ProjectRazor::Error::Slice::MissingArgument, "Option for --compare must be [equal|like]" unless !compare || compare == "equal" || compare == "like"
        raise ProjectRazor::Error::Slice::MissingArgument, "Option for --invert must be [true|false]" unless !invert || invert == "true" || invert == "false"
        matcher.key = key if key
        matcher.compare = compare if compare
        matcher.value = value if value
        matcher.inverse = invert if invert
        if tagrule.update_self
          print_object_array([matcher], "Tag Matcher updated [#{matcher.uuid}]\nTag Rule:", :success_type => :updated)
        else
          raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not update Tag Matcher")
        end
      end

      def remove_matcher
        @command = :remove_matcher
        @command_help_text << "Description: remove one Tag Matcher from the system\n"
        # load the appropriate option items for the subcommand we are handling
        option_items = { }
        # parse and validate the options that were passed in as part of this
        # subcommand (this method will return a UUID value, if present, and the
        # options map constructed from the @commmand_array)
        matcher_uuid, options = parse_and_validate_options(option_items, "razor tag matcher remove (UUID)", :require_all)
        if !@web_command
          matcher_uuid = @command_array.shift
        end
        includes_uuid = true if matcher_uuid
        # check for usage errors (the boolean value at the end of this method
        # call is used to indicate whether the choice of options from the
        # option_items hash must be an exclusive choice)
        check_option_usage(option_items, options, includes_uuid, true)

        matcher, tagrule = find_matcher(matcher_uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot find Tag Matcher with UUID [#{matcher_uuid}]" unless matcher
        raise ProjectRazor::Error::Slice::CouldNotCreate, "Could not remove Tag Matcher" unless tagrule.remove_tag_matcher(matcher.uuid)
        raise(ProjectRazor::Error::Slice::CouldNotCreate, "Could not remove Tag Matcher") unless tagrule.update_self
        print_object_array([tagrule], "Tag Matcher removed [#{matcher.uuid}]\nTag Rule:", :success_type => :removed)
      end

    end
  end
end

