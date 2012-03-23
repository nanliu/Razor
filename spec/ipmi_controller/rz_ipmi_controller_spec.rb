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
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'power', 'status').
        returns(File.read(filename))
    @ipmi.power_status(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_bmc_info_mock
    filename = @mock_data_dir + File::SEPARATOR + 'bmc-info.out'
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'bmc', 'info').
        returns(File.read(filename))
    @ipmi.bmc_info(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_bmc_getenables_mock
    filename = @mock_data_dir + File::SEPARATOR + 'bmc-getenables.out'
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'bmc', 'getenables').
        returns(File.read(filename))
    @ipmi.bmc_getenables(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_bmc_guid_mock
    filename = @mock_data_dir + File::SEPARATOR + 'bmc-guid.out'
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'bmc', 'guid').
        returns(File.read(filename))
    @ipmi.bmc_guid(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_chassis_status_mock
    filename = @mock_data_dir + File::SEPARATOR + 'chassis-status.out'
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'chassis', 'status').
        returns(File.read(filename))
    @ipmi.chassis_status(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_lan_print_mock
    filename = @mock_data_dir + File::SEPARATOR + 'lan-print.out'
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'lan', 'print').
        returns(File.read(filename))
    @ipmi.lan_print(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  def test_ipmi_fru_print_mock
    filename = @mock_data_dir + File::SEPARATOR + 'fru-print.out'
    @ipmi.expects(:run_ipmi_command).
        with(@ipmi_hostname, @ipmi_username, @ipmi_password, 'fru', 'print').
        returns(File.read(filename))
    @ipmi.fru_print(@ipmi_hostname, @ipmi_username, @ipmi_password)
  end

  describe ".IPMI" do

    it "should return the impitool power status as a hash (using the IpmiController)" do
      test_ipmi_power_status_mock.should == 'on'
    end

    it "should return the ipmitool bmc info as a hash (using the IpmiController)" do
      yaml_filename = @mock_data_dir + File::SEPARATOR + 'bmc-info.yaml'
      test_hash = YAML::load(File.open(yaml_filename))
      test_ipmi_bmc_info_mock.should == test_hash
    end

    it "should return the ipmitool bmc getenables as a hash (using the IpmiController)" do
      yaml_filename = @mock_data_dir + File::SEPARATOR + 'bmc-getenables.yaml'
      test_hash = YAML::load(File.open(yaml_filename))
      test_ipmi_bmc_getenables_mock.should == test_hash
    end

    it "should return the ipmitool bmc guid as a hash (using the IpmiController)" do
      yaml_filename = @mock_data_dir + File::SEPARATOR + 'bmc-guid.yaml'
      test_hash = YAML::load(File.open(yaml_filename))
      test_ipmi_bmc_guid_mock.should == test_hash
    end

    it "should return the ipmitool chassis status as a hash (using the IpmiController)" do
      yaml_filename = @mock_data_dir + File::SEPARATOR + 'chassis-status.yaml'
      test_hash = YAML::load(File.open(yaml_filename))
      test_ipmi_chassis_status_mock.should == test_hash
    end

    it "should return the impitool lan print as a hash (using the IpmiController)" do
      yaml_filename = @mock_data_dir + File::SEPARATOR + 'lan-print.yaml'
      test_hash = YAML::load(File.open(yaml_filename))
      test_ipmi_lan_print_mock.should == test_hash
    end

    it "should return the ipmitool fru print as a hash (using the IpmiController)" do
      yaml_filename = @mock_data_dir + File::SEPARATOR + 'fru-print.yaml'
      test_hash = YAML::load(File.open(yaml_filename))
      test_ipmi_fru_print_mock.should == test_hash
    end

  end

end