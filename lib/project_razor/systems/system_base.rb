# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

Dir.glob(ENV['RAZOR_HOME'] + '/lib/**/').each {|x| $LOAD_PATH << x} # adds ProjectRazor lib/dirs to load path


# Root namespace for ProjectRazor
# @author Nicholas Weaver
module ProjectRazor::System

  # Root namespace for Systems defined in ProjectRazor for node handoff
  # @author Nicholas Weaver
  # @abstract
  class Base

  end
end