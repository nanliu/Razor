# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
## Copyright © 2012 EMC Corporation, All Rights Reserved

require "project_razor"
require "rspec"
require "net/http"
require "json"

describe "ProjectRazor::Slice::Bmc" do

  # {"00:15:17:FA:E0:36"=>"192.168.2.51", "00:15:17:FA:DE:66"=>"192.168.2.52",
  #  "00:15:17:FA:7B:0A"=>"192.168.2.53"}
  describe ".RESTful Interface" do

    before(:all) do
      @data = ProjectRazor::Data.new
      @config = @data.config
      @data.delete_all_objects(:tag)
      @data.delete_all_objects(:node)
      @uuid = ["001517FAE036", "001517FADE66", "001517FA7B0A"]
      @mac = ["00:15:17:FA:E0:36", "00:15:17:FA:DE:66", "00:15:17:FA:7B:0A"]
      @ip = ["192.168.2.51", "192.168.2.52", "192.168.2.53"]
    end

    after(:all) do
      @data.delete_all_objects(:tag)
      @data.delete_all_objects(:node)
    end

    it "should be able to create a new empty bmc object from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/bmc/register"

      json_hash = {}
      json_hash["@uuid"] = @uuid[0]
      json_hash["@mac"] = @mac[0]
      json_hash["@ip"] = @ip[0]

      json_string = JSON.generate(json_hash)
      res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
      response_hash = JSON.parse(res.body)

      response_hash['errcode'].should == 0
      response_hash['response']['@mac'].should == @mac[0]
      response_hash['response']['@ip'].should == @ip[0]
    end

    it "should be able to get one bmc 'node' from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/bmc?#{@uuid[0]}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['response']['@uuid'].should == @uuid[0]
    end

    it "should be able to get all bmc 'nodes' from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/bmc/register"

      len = @uuid.length
      (0..len).each do
      |x|

        json_hash["@uuid"] = @uuid[x]
        json_hash["@mac"] = @mac[x]
        json_hash["@ip"] = @ip[x]

        json_string = JSON.generate(json_hash)
        res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
        response_hash = JSON.parse(res.body)

        response_hash['errcode'].should == 0
        response_hash['response']['@mac'].should == @mac[x]
        response_hash['response']['@ip'].should == @ip[x]
      end

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/bmc"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      bmc_nodes = res_hash['response']
      bmc_nodes.count.should == len
    end

    it "should be able to get all bmc 'nodes' that match attributes from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/bmc?@ip=regex:192\.168\.2\.5[1-2]"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      tag_rules = res_hash['response']

      tag_rules.sort do
        |a,b|
        a["@ip"] <=> b["@ip"]
      end
      tag_rules.count.should = 2
      tag_rules[0]['@mac'].should == "00:15:17:FA:E0:36"
      tag_rules[1]['@mac'].should == "00:15:17:FA:DE:66"
    end

  end

end