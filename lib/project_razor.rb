# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


$config_server_path = "#{File.dirname(__FILE__).sub(/\/lib$/,"/conf")}/razor_server.conf"
$img_svc_path = File.dirname(__FILE__).sub(/\/lib$/,"/image")

require "project_razor/object"
require "project_razor/data"
require "project_razor/logging"
require "project_razor/utility"
require "project_razor/config"
require "project_razor/node"
require "project_razor/policy"
require "project_razor/engine"
require "project_razor/slice"
require "project_razor/persist"
require "project_razor/model"
require "project_razor/tagging"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  # Namespace root
end