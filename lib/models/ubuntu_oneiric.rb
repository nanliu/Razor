# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/models"

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