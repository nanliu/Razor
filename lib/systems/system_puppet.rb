$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/systems"

require "system_base"

# Root namespace for Razor
# @author Nicholas Weaver
module Razor::System

  # Root namespace for Systems defined in Razor for node handoff
  # @author Nicholas Weaver
  class PuppetAgent < Razor::System::Base

  end
end