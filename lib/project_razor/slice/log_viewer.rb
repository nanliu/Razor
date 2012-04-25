# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "pp"

# Root namespace for LogViewer objects
# used to find them in object space for type checking
LOGVIEWER_PREFIX = "ProjectRazor::LogViewer::"

# do a bit of "monkey-patching" of the File class so that we'll have access to a few
# additional methods from within our Logviewer Slice
class File

  # First, define a buffer size that is used for reading the file in chunks
  # in the each_chunk and tail methods, below
  BUFFER_SIZE = 4096

  # and define the default number of lines to include in a "tail" if not
  # specified in the input to the "tail" function (or if the value that
  # is passed in is a nil value)
  DEFAULT_NLINES_TAIL = 10

  # Here, we extend the File class with a new method (each_chunk) that can
  # be used to iterate through a file and return that file to the caller
  # in chunks of "chunk_size" bytes
  #
  # @param [Integer] chunk_size
  # @return [Object]
  def each_chunk(chunk_size=BUFFER_SIZE)
    yield read(chunk_size) until eof?
  end

  # Here, we extend the File class with a new method (tail) that will return
  # the last N lines from the corresponding file to the caller (as an array)
  #
  # @param [Integer] num_lines - the number of lines to read from from the "tail" of
  # the file (defaults to DEFAULT_NLINES_TAIL lines if not included in the method call)
  # @return [Array]  the last N lines from the file, where N is the input argument
  # (or the entire file if the number of lines is less than N)
  def tail(num_lines=DEFAULT_NLINES_TAIL)
    # if the number of lines passed in is nil, use the default value instead
    num_lines = DEFAULT_NLINES_TAIL unless num_lines
    # initialize a few variables
    idx = 0
    bytes_read = 0
    next_buffer_size = BUFFER_SIZE
    # handle the case where the file size is less than the BUFFER_SIZE
    # correctly (in that case, will read the entire file in one chunk)
    if size > BUFFER_SIZE
      idx = (size - BUFFER_SIZE)
    else
      next_buffer_size = size
    end
    chunks = []
    lines = 0
    # As long as we haven't read the number of lines requested
    # and we haven't read the entire file, loop through the file
    # and read it in chunks
    begin
      # seek to the appropriate position to read the next chunk, then
      # read it
      seek(idx)
      chunk = read(next_buffer_size)
      # count the number of lines in the chunk we just read and add that
      # chunk to the buffer; while we are at it, determine how many bytes
      # were just read and increment the total number of bytes read
      lines += chunk.count("\n")
      chunks.unshift chunk
      bytes_read += chunk.size
      # if there is more than a buffer prior to the chunk we just read, then
      # shift back by an entire buffer for the next read, otherwise just
      # move back to the start of the file and set the next_buffer_size
      # appropriately
      if idx > BUFFER_SIZE
        next_buffer_size = BUFFER_SIZE
        idx -= BUFFER_SIZE
      else
        next_buffer_size = idx
        idx = 0
      end
    end while lines < ( num_lines + 1 ) && bytes_read < size
    # now that we've got the number of lines we wanted (or have read the entire
    # file into our buffer), parse it and extract the last "num_lines" lines from it
    tail_of_file = chunks.join('')
    ary = tail_of_file.split(/\n/)
    lines_to_return = ary[-num_lines..-1]
  end

end

# and monkey patch the JSON class to add an is_json? method
module JSON
  def self.is_json?(foo)
    begin
      return false unless foo.is_a?(String)
      JSON.parse(foo).all?
    rescue JSON::ParserError
      false
    end
  end
end

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice

    # ProjectRazor Slice System
    # Used for system management
    # @author Nicholas Weaver
    class Logviewer < ProjectRazor::Slice::Base

      # Initializes ProjectRazor::Slice::System including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)

        super(args)
        @new_slice_style = true # switch to new slice style

        # define a regular expression to use for matching with JSON strings

        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:tail => { /[0-9]+/ => {:default => "tail_razor_log",
                                                   :filter => "tail_then_filter_razor_log",
                                                   :help => "razor logviewer tail [filter filterexp]"}},

                           :filter => { /{.*}/ => {:default => "filter_razor_log",
                                                   :tail => "filter_then_tail_razor_log",
                                                   :help => "razor logviewer filter EXPR [tail NLINES]"}},
                           :default => "view_razor_log",
                           :else => :help,
                           :help => "razor logviewer [tail nlines] [filter regexp]"
        }
        @slice_name = "Logviewer"
        @logfile = File.join(get_logfile_path, "project_razor.log")
      end

      # uses the location of the Razor configuration file to determine the path to the
      # ${RAZOR_HOME}/log directory (which is where the logfiles for Razor are located)
      def get_logfile_path
        # split the path into an array using the File::SEPARATOR as the separator
        conf_dir_parts =  $config_server_path.split(File::SEPARATOR)
        # and extract all but the last two pieces (which will contain the configuration
        # directory name and the name of the configuration file)
        logfile_path_parts = conf_dir_parts[0...-2]
        # append the "log" directory name to the array, and join that array back together
        # using the File.join() method
        logfile_path_parts << "log"
        File.join(logfile_path_parts)
      end

      # Returns the contents from the current razor logfile
      def view_razor_log

        if @web_command

          # if it's a web command, grab the logfile contents and return them as a JSON string

        else

          # else, just read that logfile and print the contents to the command line
          File.open(@logfile, 'r').each_chunk { |chunk|
            print chunk
          }

        end
      end

      def tail_razor_log
        begin
          num_lines_tail = @last_arg.to_i
        rescue => e
          logger.error e.message
        end
        File.open(@logfile) { |file|
          tail_of_file = file.tail(num_lines_tail)
          tail_of_file.each { |line|
            puts line
          }
        }

      end

      def tail_then_filter_razor_log
        # then, peek into the first element down in the stack of previous arguments
        # (which should be the number of lines to tail before filtering)
        num_lines_tail = @prev_args.peek(1)
        # and grab the next argument (which should be the filter expression)
        puts "tail #{num_lines_tail} from the razor log, then apply a filter...not yet implemented"
      end

      def filter_then_tail_razor_log
        # then, peek into the first element down in the stack of previous arguments
        # (which should be the expression to use as a filter on the log before tailing
        # the result)
        filter_expression_str = @prev_args.peek(1)
        # now, parse the filter_expression_str to get the parts (should be a JSON string with
        # key-value pairs where the values are regular expressions and the keys include one or more
        # of the following:  log_level, elapsed_time, class_name, or pattern)
        if JSON.is_json?(filter_expression_str)
          log_level_match_str = nil
          elapsed_time_str = nil
          class_name_match_str = nil
          pattern_match_str = nil
          match_criteria = JSON.parse(filter_expression_str)
          match_criteria.each { |key, value|
            case key
              when "log_level"
                log_level_match_str = value
              when "elapsed_time"
                elapsed_time_str = value
              when "class_name"
                class_name_match_str = value
              when "pattern"
                pattern_match_str = value
              else
                puts "Unrecognized key in filter expression: #{key}"
                puts "\tvalid values include 'log_level', 'elapsed_time', 'class_name', or 'pattern'"
            end
          }
          # and grab the next argument (which should be the number of lines to tail from the result)
          puts "filter razor log using the following criteria (then tail the result):"
          puts "\tlog_level => #{PP.pp(log_level_match_str, "")}" if log_level_match_str
          puts "\telapsed_time => #{PP.pp(elapsed_time_str, "")}" if elapsed_time_str
          puts "\tclass_name => #{PP.pp(class_name_match_str, "")}" if class_name_match_str
          puts "\tpattern => #{PP.pp(pattern_match_str, "")}" if pattern_match_str
          puts "this method is not yet implemented..."
        else
          # if get here, it's an error (the string passed in wasn't a JSON string)
          puts "The filter expression #{filter_expression_str} is not a JSON string"
        end

      end

      # Returns the system types available
      def get_system_types
        # We use the common method in Utility to fetch object types by providing Namespace prefix
        print_object_array get_types_as_object_types(SYSTEM_PREFIX), "\nPossible System Types:"
      end

      #def get_system_with_uuid
      #  @command_help_text = "razor system get all|type|(uuid)"
      #  @arg = @command_array.shift
      #  system = get_object("system instances", :systems, @arg)
      #  case system
      #    when nil
      #      slice_error("Cannot Find System with UUID: [#@arg]")
      #    else
      #      print_object_array [system]
      #  end
      #end

      #def add_system
      #  # Set the command we have selected
      #  @command =:add
      #  # Set out help text
      #  @command_help_text = "razor system " + "(system type) (Name) (Description) [(server hostname),{server hostname}]".yellow
      #  # If a REST call we need to populate the values from the provided JSON string
      #  if @web_command
      #    # Grab next arg as json string var
      #    json_string = @command_array.first
      #    # Validate JSON, if valid we treat like a POST VAR request. Otherwise it passes on to CLI which handles GET like CLI
      #    if is_valid_json?(json_string)
      #      # Grab vars as hash using sanitize to strip the @ prefix if used
      #      @vars_hash = sanitize_hash(JSON.parse(json_string))
      #      # System type (must match a proper system type)
      #      @type = @vars_hash['type']
      #      # System Name (user defined)
      #      @name = @vars_hash['name']
      #      # System User Description (user defined)
      #      @user_description = @vars_hash['description']
      #      # System Servers (user defined comma-delimited list of servers, must be at list one)
      #      @servers = @vars_hash['servers']
      #    else
      #      #Same vars as above but pulled from CLI arg / Web PATH
      #      @type, @name, @user_description, @servers = *@command_array
      #    end
      #  end
      #  @type, @name, @user_description, @servers = *@command_array unless @type || @name || @user_description || @servers
      #  # Validate our args are here
      #  return slice_error("Must Provide System Type [type]") unless validate_arg(@type)
      #  return slice_error("Must Provide System Name [name]") unless validate_arg(@name)
      #  return slice_error("Must Provide System Description [description]") unless validate_arg(@user_description)
      #  return slice_error("Must Provide System Servers [servers]") unless validate_arg(@servers)
      #  # Convert our servers var to an Array if it is not one already
      #  @servers = @servers.split(",") unless @servers.respond_to?(:each)
      #  return slice_error("Must Provide At Least One System Server [servers]") unless @servers.count > 0
      #  # We use the [is_valid_type?] method from Utility to validate our type vs our object namespace prefix
      #  unless is_valid_type?(SYSTEM_PREFIX, @type)
      #    # Return error
      #    slice_error("InvalidSystemType")
      #    # Also print possible types if not a REST call
      #    get_system_types unless @web_command
      #    return
      #  end
      #  new_system = new_object_from_type_name(SYSTEM_PREFIX, @type)
      #  new_system.name = @name
      #  new_system.user_description = @user_description
      #  new_system.servers = @servers
      #  setup_data
      #  @data.persist_object(new_system)
      #  if new_system
      #    @command_array.unshift(new_system.uuid)
      #    get_system_with_uuid
      #  else
      #    slice_error("CouldNotSaveSystem")
      #  end
      #end

      #def remove_system
      #  @command_help_text = "razor system remove all|(uuid)"
      #  # Grab the arg
      #  @arg = @command_array.shift
      #  case @arg
      #    when "all" # if [all] we remove all instances
      #      setup_data # setup the data object
      #      @data.delete_all_objects(:systems) # remove all system instances
      #      slice_success("All System deleted") # return success
      #    when nil
      #      slice_error("Command Error") # return error for no arg
      #    else
      #      system = get_object("system instances", :systems, @arg) # attempt to find system with uuid
      #      case system
      #        when nil
      #          slice_error("Cannot Find System with UUID: [#@arg]") # error when it is invalid
      #        else
      #          setup_data
      #          @data.delete_object_by_uuid(:systems, @arg)
      #          slice_success("System deleted")
      #      end
      #  end
      #end

    end
  end
end

