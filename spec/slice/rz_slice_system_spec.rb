# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
## Copyright © 2012 EMC Corporation, All Rights Reserved

require "project_razor"
require "rspec"
require "net/http"
require "json"


describe "ProjectRazor::Slice::System" do

  describe ".RESTful Interface" do

    before(:all) do
      @data = ProjectRazor::Data.new
      @config = @data.config
      @data.delete_all_objects(:systems)
    end

    after(:all) do
      #@data.delete_all_objects(:systems)
    end

    it "should be able to get systems types from REST" do
      # We create an array to test the different possible ways to get system types
      uri_array = []
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/type")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/types")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/t")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/get/type")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/get/types")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/get/t")
      uri_array.each do |uri|
        res = Net::HTTP.get(uri)
        res_hash = JSON.parse(res)
        systems_types = res_hash['response']
        systems_types.count.should > 0
        puppet_flag = false # We will just check for the puppet system type
        systems_types.each {|t| puppet_flag = true if t["@type"] == "puppet"}
        puppet_flag.should == true
      end
    end

    it "should be able to create system instance from REST using GET" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/add?type=puppet&name=RSPECPuppetGET&description=RSPECSystemInstanceGET&servers=rspecpuppet.example.org"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['result'].should == 'success'
      system_response_array = res_hash['response']
      $system_uuid_get = system_response_array.first['@uuid']
      $system_uuid_get.should_not == nil
    end

    it "should be able to create system instance from REST using POST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/add"
      json_hash = {}
      json_hash["type"] = "puppet"
      json_hash["name"] = "RSPECPuppetPOST"
      json_hash["description"] = "RSPECSystemInstancePOST "
      json_hash["servers"] = ["rspecpuppet.example.org"]
      json_string = JSON.generate(json_hash)
      res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
      res_hash = JSON.parse(res.body)
      res_hash['result'].should == 'success'
      system_response_array = res_hash['response']
      $system_uuid_post = system_response_array.first['@uuid']
      $system_uuid_post.should_not == nil
    end

    it "should be able to list all systems instances from REST" do
      # We create an array to test the different possible ways to get system types
      uri_array = []
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/get")
      uri_array.each do |uri|
        res = Net::HTTP.get(uri)
        res_hash = JSON.parse(res)
        systems_types = res_hash['response']
        systems_types.count.should == 2
      end
    end

    it "should be able to find specific system instances by UUID from REST" do
      # We create an array to test the different possible ways to get system types
      uri_array = []
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/#{$system_uuid_get}")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/get/#{$system_uuid_get}")
      uri_array.each do |uri|
        res = Net::HTTP.get(uri)
        res_hash = JSON.parse(res)
        system_response_array = res_hash['response']
        system_response_array.count.should == 1
        system_response_array.first['@uuid'].should == $system_uuid_get
      end
    end

    it "should be able to find specific system instances by attribute from REST" do
      uri_array = []
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/get?name=regex:GET")
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system?name=regex:GET")
      uri_array.each do |uri|
        res = Net::HTTP.get(uri)
        res_hash = JSON.parse(res)
        res_hash['result'].should == 'success'
        system_response_array = res_hash['response']
        system = system_response_array.first
        system['@uuid'].should == $system_uuid_get
      end

      uri_array = []
      uri_array << (URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/get?name=RSPECPuppetPOST")
      uri_array.each do |uri|
        res = Net::HTTP.get(uri)
        res_hash = JSON.parse(res)
        res_hash['result'].should == 'success'
        system_response_array = res_hash['response']
        system = system_response_array.first
        system['@uuid'].should == $system_uuid_post
      end
    end

    it "should be able to delete specific system instances from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/remove/#{$system_uuid_get}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['result'].should == 'success'

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/#{$system_uuid_get}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['errcode'].should == 1

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/remove/#{$system_uuid_post}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['result'].should == 'success'

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/#{$system_uuid_post}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['errcode'].should == 1

    end

    it "should be able to delete all system instances from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/add"
      json_hash = {}
      json_hash["type"] = "puppet"
      json_hash["description"] = "RSPECSystemInstancePOST "
      json_hash["servers"] = ["rspecpuppet.example.org"]
      (1..10).each do |x|
        json_hash["name"] = "RSPECPuppetPOST#{x}"
        json_string = JSON.generate(json_hash)
        res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
        res_hash = JSON.parse(res.body)
        res_hash['result'].should == 'success'
        system_response_array = res_hash['response']
        $system_uuid_post = system_response_array.first['@uuid']
        $system_uuid_post.should_not == nil
      end

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      systems_get = res_hash['response']
      systems_get.count.should == 10

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system/remove/all"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['errcode'].should == 0

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/system"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      systems_get = res_hash['response']
      systems_get.count.should == 0
    end
  end
end