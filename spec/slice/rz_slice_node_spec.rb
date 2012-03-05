# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "project_razor"
require "rspec"
require "net/http"
require "json"

describe "ProjectRazor::Slice::Node" do

  describe ".RESTful Interface" do

    before(:all) do
      @data = ProjectRazor::Data.new
      @config = @data.config

      @uuid = "TEST#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
    end

    after(:all) do
      @data.delete_all_objects(:node)

    end

    it "Should be able to register a node by uuid from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/node/register" # root URI for node slice actions


      state = "idle"

      json_hash = {}
      json_hash["@uuid"] = @uuid
      json_hash["@last_state"] = state
      json_hash["@attributes_hash"] = {"hostname" => "nick01.example.com",
                                       "ip_address" => "1.1.1.1"}

      json_string = JSON.generate(json_hash)
      res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
      response_hash = JSON.parse(res.body)

      response_hash['errcode'].should == 0
      response_hash['response']['@uuid'].should == @uuid
    end


    it "Should be able to query a list of nodes from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/node"

      res = Net::HTTP.get(uri)
      response_hash = JSON.parse(res)

      response_hash['errcode'].should == 0
      nodes = response_hash['response']
      nodes.count.should > 0
      nodes.each do
        |node|
        node['@uuid'].should_not == nil
      end
    end

    it "Should be able to query a single node by uuid from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/node?@uuid=#{@uuid}"

      res = Net::HTTP.get(uri)
      response_hash = JSON.parse(res)

      response_hash['errcode'].should == 0
      nodes = response_hash['response']
      nodes.count.should == 1
      nodes.each do
      |node|
        node['@uuid'].should == @uuid
      end
    end

    it "Should be able to checkin a node by uuid from REST and get back acknowledge" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/node/checkin?uuid=#{@uuid}&last_state=idle_error"

      res = Net::HTTP.get(uri)
      response_hash = JSON.parse(res)

      response_hash['errcode'].should == 0
      response_hash['response']['command_name'].should == "acknowledge"

      node = @data.fetch_object_by_uuid(:node, @uuid)
      node.last_state.should == "idle_error"

    end

    it "Should be able to checkin a node by uuid from REST and get back register" do
      node = @data.fetch_object_by_uuid(:node, @uuid)
      node.timestamp = 0 # force node register timeout to have been expired
      node.update_self
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/node/checkin?uuid=#{@uuid}&last_state=idle"

      res = Net::HTTP.get(uri)
      response_hash = JSON.parse(res)

      response_hash['errcode'].should == 0
      response_hash['response']['command_name'].should == "register"

      node.refresh_self
      node.last_state.should == "idle"
    end

    it "Should be able to checkin a node by uuid from REST and get a reboot command back (forced through checkin_action.yaml)" do
      # This requires that checkin_action.yaml have the 'TESTRSPEC': :reboot  set


      # First create test node

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/node/register" # root URI for node slice actions
      json_hash = {}
      json_hash["@uuid"] = "TESTRSPEC"
      json_hash["@last_state"] = "idle"
      json_hash["@attributes_hash"] = {"hostname" => "nick01.example.com",
                                       "ip_address" => "1.1.1.1"}

      json_string = JSON.generate(json_hash)
      res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
      response_hash = JSON.parse(res.body)

      response_hash['errcode'].should == 0
      response_hash['response']['@uuid'].should == "TESTRSPEC"


      # Now lets checkin
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/node/checkin?uuid=TESTRSPEC&last_state=idle_error"

      res = Net::HTTP.get(uri)
      response_hash = JSON.parse(res)

      response_hash['errcode'].should == 0
      response_hash['response']['command_name'].should == "reboot"

      node = @data.fetch_object_by_uuid(:node, "TESTRSPEC")
      node.last_state.should == "idle_error"


    end

  end
end