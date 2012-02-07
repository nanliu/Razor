#!/usr/bin/env ruby
#
# Primary control for Razor
# Modules are dynamically loaded and accessed through corresponding namespace
# Format will be 'razor [module namespace] [module args{}]'
#
# This adds Razor Common lib path to the load path for this child proc

require "extlib"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
MODULE_PATH = "#{ENV['RAZOR_HOME']}/lib/slices"
SLICE_PREFIX = "Razor::Slice::"

# Dynamically loads Modules from $RAZOR_HOME/lib/slices
def load_modules
  Dir.glob("#{MODULE_PATH}/*.{rb}") do |file|
    require "#{file}"
  end
end

# @param [String] namespace
# @param [Array]  args
def call_razor_slice(namespace, args)
  puts "\n______\nCalling: #{namespace}"
  razor_module = Object.full_const_get(SLICE_PREFIX + namespace.capitalize).new(args)
  razor_module.slice_call
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




# Detects if running from command line
if $0 == __FILE__
  load_modules

  puts "\nRazor"
  puts "-----"
  puts "Command line control"
  puts "____________________"
  puts "Loaded slices:"
  puts ""

  get_slices_loaded.each do |slice|
    puts "\t#{slice.downcase}"
    #call_razor_slice(slice, [1,2,3])
  end
  namespace = ARGV.shift
  args = ARGV
  args << "---\n:@name: mk0123456789\n:@uuid: '0123456789'\n:@attributes_hash:\n  a: 1\n  b: 2\n  c: 3\n"
  call_razor_slice(namespace, args)
end


