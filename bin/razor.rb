#!/usr/bin/env ruby
#
# Primary control for Razor
# Modules are dynamically loaded and accessed through corresponding namespace
# Format will be 'razor [module namespace] [module args{}]'
#
# This adds Razor Common lib path to the load path for this child proc

require "extlib"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
MODULE_PATH = "#{ENV['RAZOR_HOME']}/lib/slices/*.{rb}"

# Dynamically loads Modules from $RAZOR_HOME/lib/slices
def load_modules
  Dir.glob(MODULE_PATH) do |file|
    puts "require #{file}"
    require "#{file}"
  end
end

# @param [String] namespace
# @param [Array]  args
def call_razor_module(namespace, args)
  razor_module = Object.full_const_get(namespace)
  puts razor_module.inspect
end




# Detects if running from command line
if $0 == __FILE__
  puts "Razor"
  load_modules
  call_razor_module("Razor::Slices:Node",[])
end


