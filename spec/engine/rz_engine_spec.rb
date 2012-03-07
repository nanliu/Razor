# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "rspec"
require "project_razor"

describe ProjectRazor::Engine do

  it "should do something" do
    engine = ProjectRazor::Engine.instance

    engine.boot_checkin("1234567890")

  end

end