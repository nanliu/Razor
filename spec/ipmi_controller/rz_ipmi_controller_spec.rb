# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "project_razor"
require "project_razor/power_control/ipmi_controller"
require "rspec"
require "net/http"
require "net/http"
require "mocha"
require "yaml"

describe ProjectRazor::PowerControl::IpmiController do

  before (:all) do
    @ipmi = ProjectRazor::PowerControl::IpmiController.instance
    data = ProjectRazor::Data.new
    config = data.config
    #@localdir = $razor_root  + File::SEPARATOR + "spec" + File::SEPARATOR + "ipmi_controller" +
    #    File::SEPARATOR + 'ipmitool-mock-files'
    @mock_data_dir = File.dirname(__FILE__) + File::SEPARATOR + 'ipmitool-mock-files'
    @ipmi_username = config.default_ipmi_username
    @ipmi_password = config.default_ipmi_password
    @ipmi_hostname = '192.168.2.51'
    # Clean stuff out
    #@data.delete_all_objects(:node)
    #@data.delete_all_objects(:policy_rule)
    #@data.delete_all_objects(:bound_policy)
    #@data.delete_all_objects(:tag)
  end

  after (:all) do
    # Clean out what we did
    #@data.delete_all_objects(:node)
    #@data.delete_all_objects(:policy_rule)
    #@data.delete_all_objects(:bound_policy)
    #@data.delete_all_objects(:tag)
  end

  def test_ipmi_power_status_mock
    filename = @mock_data_dir + File::SEPARATOR + 'power-status.out'
    @ipmi.expects(:system).with(/ipmitool.*power status/).returns(File.read(filename))
    @ipmi.power_status(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_lan_print_mock
    filename = @mock_data_dir + File::SEPARATOR + 'lan-print.out'
    @ipmi.expects(:system).with(/ipmitool.*lan print/).returns(File.read(filename))
    @ipmi.power_status(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  describe ".IPMI" do

    it "should return the power status for a node using via the IpmiController" do
      #test_str = YAML::load(File.open('ipmitool-mock-files/power-status.yaml')
      test_ipmi_power_status_mock.should == 'on'
    end

    it "should return the lan print information for a node via the IpmiController" do
      yaml_filename = @mock_data_dir + File::SEPARATOR + 'lan-print.yaml'
      test_hash = YAML::load(File.open(yaml_filename))
      test_ipmi_lan_print_mock.should == test_hash
    end

  end

end