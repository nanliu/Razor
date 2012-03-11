# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "project_razor"
require "rspec"

describe ProjectRazor::ImageService do


  describe ".Microkernel" do
    it "should do something" do
      new_mk = ProjectRazor::ImageService::MicroKernel.new({})
      resp = new_mk.add("~/Documents/rz_mk-image-dev-0.2.0.0.iso","./")
      p  resp
    end

  end
end