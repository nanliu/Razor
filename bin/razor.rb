#!/usr/bin/env ruby
#
# Primary control for Razor
# Modules are dynamically loaded and accessed through corresponding namespace
# Format will be 'razor [module namespace] [module args{}]'
#
# This adds Razor Common lib path to the load path for this child proc


$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
MODULE_PATH = "#{ENV['RAZOR_HOME']}/lib/slices"
SLICE_PREFIX = "Razor::Slice::"

require "extlib"
require "object"
require "json"


# Dynamically loads Modules from $RAZOR_HOME/lib/slices
def load_modules
  @obj = Razor::Object.new
  @version = @obj.get_razor_version
  Dir.glob("#{MODULE_PATH}/*.{rb}") do |file|
    require "#{file}"
  end
end

# @param [String] namespace
# @param [Array]  args
def call_razor_slice
  begin
    razor_module = Object.full_const_get(SLICE_PREFIX + @namespace.capitalize).new(@args)
    razor_module.web_command = @web_command
    razor_module.slice_call
  rescue
    if @web_command
      p JSON.dump({"slice" => "Razor::Slice", "result" => "InvalidSlice"})
    else
      print_header
      print "\n [#{@namespace.capitalize}] ".red
      print "<-Invalid Slice \n".yellow
    end

  end
end

def get_slices_loaded
  temp_hash = {}
  ObjectSpace.each_object do
  |object_class|

    if object_class.to_s.start_with?(SLICE_PREFIX) && object_class.to_s != SLICE_PREFIX
      temp_hash[object_class.to_s] = object_class.to_s.sub(SLICE_PREFIX,"")
    end
  end
  temp_array = []
  temp_hash.each {|x,y| temp_array << y}
  temp_array
end


def print_header
  puts "\n\n\nRazor - #{@version}".bold.green
  puts "EMC Corporation".green
  puts "\nLoaded slices:"

  x = 0
  get_slices_loaded.each do |slice|
    x += 1
    print "[#{slice.downcase}] ".yellow unless slice.downcase == "base"
    if x > 3
      print "\n"
      x = 1
    end
  end
  print "\n"
  puts "\n\tUsage: ".bold
  print "\n\trazor "
  print "[slice name] [command argument] [command argument]...\n\n".blue
end

# Detects if running from command line
if $0 == __FILE__
  load_modules
  @web_command = false



  if ARGV.count > 0
    while ARGV[0].start_with?("-")
      switch = ARGV.shift
      case switch
        when "-w"
          @web_command = true
      end
    end
    @namespace = ARGV.shift
    @args = ARGV
    call_razor_slice
  else
    if !@web_command
      print_header

    end
  end


end


