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
    @mock_data_dir = File.expand_path(File.dirname(__FILE__)) + File::SEPARATOR + 'ipmitool-mock-files'
    data = ProjectRazor::Data.new
    config = data.config
    @ipmi_username = config.default_ipmi_username
    @ipmi_password = config.default_ipmi_password
    @ipmi_hostname = '192.168.2.51'
    # Clean stuff out
  end

  after (:all) do
    # Clean out what we did
  end

  def test_ipmi_power_status_mock
    filename = @mock_data_dir + File::SEPARATOR + 'power-status.out'
    puts filename
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'power', 'status').
        returns(File.read(filename))
    @ipmi.power_status(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_lan_print_mock
    filename = @mock_data_dir + File::SEPARATOR + 'lan-print.out'
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password,'lan', 'print').
        returns(File.read(filename))
    @ipmi.lan_print(@ipmi_hostname, @ipmi_username, @ipmi_password)
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