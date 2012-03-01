# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

Dir.glob(ENV['RAZOR_HOME'] + '/lib/**/').each {|x| $LOAD_PATH << x} # adds Razor lib/dirs to load path


require "model_base"

# Root Razor namespace
# @author Nicholas Weaver
module Razor::Model
  # Root Model object
  # @author Nicholas Weaver
  # @abstract
  class UbuntuOneiric < Razor::Model::Base

    def initialize(hash)
      super(hash)
      @model_type = :ubuntu_oneiric
      @model_description = "Ubuntu Oneiric 11.10"


    end

    def define_values_hash
      @values_hash
    end

  end
end