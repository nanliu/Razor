# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "object"

# Razor Policy class
# Used to apply Razor::Model to Razor::Node
module Razor
  class TagRule < Razor::Object

    attr_accessor :name
    attr_accessor :tag
    attr_accessor :attribute_matcher

    # To change this template use File | Settings | File Templates.
  end
end