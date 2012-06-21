require "json"
require "yaml"

# Root ProjectRazor namespace
module ProjectRazor
  module Slice

    # TODO - add inspection to prevent duplicate MK's with identical version to be added

    # ProjectRazor Slice Image
    # Used for image management
    class ImageDemo < ProjectRazor::Slice::Base

      attr_accessor :options
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super([])
        @hidden = false
        @args = args
        @exit_code = 0
        @command_type = [:cli, :rest]
        @help_cmd = ''
        @options = {}
        @require_options = {}
      end

      def opts(cmd=@command)
        case cmd
        when 'add'
          @command_type = [:cli, :rest]
          # This is to bailout the old cli format and web calls:
          @require_options = [ :type, :path, :name, :version ]

          @expect_uuid   = false
          opts_parser = OptionParser.new do |opts|
            opts.banner = "Usage: "+"razor image add [command options] ...".red
            opts.separator ""
            opts.separator "Command Options:".yellow

            opts.on('-t', '--type TYPE', 'image type.')          { |type| @options[:type] = type }
            opts.on('-p', '--path PATH', 'image filepath.')      { |path| @options[:path] = path }
            opts.on('-n', '--name NAME', 'image name.')          { |name| @options[:name] = name }
            opts.on('-v', '--version VERSION', 'image version.') { |ver|  @options[:version] = ver }

            opts.on_tail('-h', '--help', 'This help message.') { display_help; @exit_code=129; exit(@exit_code) }
          end
        when 'get'
          @command_type = [:cli]
          @expect_uuid = true
          opts_parser = OptionParser.new do |opts|
            opts.banner = "Usage: "+"razor image get [uuid]".red

            opts.on_tail('-h', '--help', 'This help message.') { display_help; @exit_code=129; exit(@exit_code) }
          end
        when 'path'
          @command_type = [:rest]
          @expect_uuid = true
          opts_parser = OptionParser.new do |opts|
            opts.banner = "Usage: "+"razor -w image path [type] [file] (REST only)".red

            opts.on('-t', '--type TYPE', 'image type.')        { |type| @options[:type] = type }
            opts.on('-f', '--file FILE', 'image file.')        { |file| @options[:file] = file }
            opts.on_tail('-h', '--help', 'This help message.') { display_help; @exit_code=129; exit(@exit_code) }
          end
        when 'remove'
          @command_type = [:cli, :rest]
          opts_parser = OptionParser.new do |opts|
            opts.banner = "Usage: "+"razor image remove [uuid]".red

            opts.on_tail('-h', '--help', 'This help message.') { display_help; @exit_code=129; exit(@exit_code) }
          end
          @expect_uuid = true
        when /^help/
          #puts self.respond_to?(@command.to_sym)
          #puts self.methods.include?(@command)
          self.send(@command.to_sym) if self.respond_to?(@command.to_sym)
        else
          @command_type = [:cli, :rest]
          # TODO: we can try to be smarter about available commands and banner
          #@command = ''
          commands = %w[ add get path remove ]
          opts_parser = OptionParser.new do |opts|
            opts.banner = "Usage: "+"razor image [#{commands.join('|')}]".red
            opts.separator ""
            opts.separator "Available Commands:"
            opts.separator "  razor image add [command options]".yellow
            opts.separator "  razor image get [uuid]".yellow
            opts.separator "  razor -w image path [type] [file] (This command is REST only)".yellow
            opts.separator "  razor image remove [uuid]".yellow
            opts.separator ""
            opts.separator "Available Options:"

            opts.on_tail('-h', '--help', 'This help message.') { display_help }
          end
        end
      end

      def slice_call
        run
      end

      def run
        parse_command!
        parse_options!
        verify_command(@options, @require_options)
        results = execute(@args)

        # technically whether to print should be decided by cli
        if @web_command
          puts results.to_json
        else
          puts results.to_s
        end
      end

      def verify_command(options, req_opt)
        if @web_command
          mode = :rest
        else
          mode = :cli
        end
        raise ProjectRazor::Error::Slice::NotImplemented, "#{@command} does not support #{mode.to_s} mode." unless @command_type.include?(mode.to_sym)
        req_opt.each do |opt|
          unless options.include?(opt)
            @help_cmd = @command
            @command = "help_#{opt}" if self.respond_to?("help_#{opt}".to_sym)
            raise ProjectRazor::Error::Slice::MissingArgument.new("Missing slice option: #{opt}")
          end
        end
      end

      def parse_command!
        @command = @args.shift
        raise ProjectRazor::Error::Slice::InvalidCommand, "Missing slice command." if (@command.nil? or @command.empty?)
        @command
      end

      def parse_options!
        @args = opts.order!(@args)
        self
      end

      def image_types
        slice_prefix = 'ProjectRazor::ImageService::'
        slices = ProjectRazor::ImageService.class_children.map do |i|
          image = i.new({ })
          image.path_prefix unless image.hidden
        end
        slices.compact
      end

      def help_type
        "Valid images types are: " + image_types.inspect.red + "\n" + opts(@help_cmd).help
      end

      def display_help
        puts opts
        @exit_code = 129
      end

      def execute(options)
        self.send(@command.to_s)
      end

      def verify_type(type)
        #unless ['os', 'mk', 'esx'].include?(type)
        #  @help_cmd = @command
        #  @command = 'help_type'
        #  raise ProjectRazor::Error::Slice::InvalidCommand, "invalid type"
        #end
      end

      def add()
        puts options[:type]
        verify_type(@options[:type])
        {:msg => "adding images with #{@options.inspect}"}
      end

      def path()
        { :msg => "",
          :path => "found image path with #{@options.inspect}" 
        }
      end
    end
  end
end
