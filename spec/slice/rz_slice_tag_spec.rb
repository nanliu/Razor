# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
## Copyright © 2012 EMC Corporation, All Rights Reserved

require "project_razor"
require "rspec"
require "net/http"
require "json"

describe "ProjectRazor::Slice::Tag" do

  describe ".RESTful Interface" do

    before(:all) do
      @data = ProjectRazor::Data.new
      @config = @data.config
      @data.delete_all_objects(:tag)
      @uuid = "TEST#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
    end

    after(:all) do
      @data.delete_all_objects(:tag)
    end

    it "should be able to create a new empty tag rule from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/add"

      name = "test_tag_rule"
      tag = "RSPEC"

      json_hash = {}
      json_hash["@uuid"] = @uuid
      json_hash["@name"] = name
      json_hash["@tag"] = tag
      json_hash["@tag_matchers"] = []

      json_string = JSON.generate(json_hash)
      res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
      response_hash = JSON.parse(res.body)

      response_hash['errcode'].should == 0
      response_hash['response']['@name'].should == name
      response_hash['response']['@tag'].should == tag
    end

    it "should be able to get one tag rule from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/#{@uuid}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['response']['@uuid'].should == @uuid
    end


    it "should be able to create a tag matchers for a tag rule from REST" do

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/#{@uuid}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['response']['@uuid'].should == @uuid
      tag_rule = ProjectRazor::Tagging::TagRule.new(res_hash['response'])
      tag_rule.uuid.should == @uuid

      tag_rule.tag_matchers.count.should == 0

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/matcher/add/#{@uuid}"
      json_hash = {}
      json_hash["@key"] = "hostname"
      json_hash["@value"] = "nick01"
      json_hash["@compare"] = "equal"
      json_hash["@inverse"] = "false"
      json_string = JSON.generate(json_hash)
      res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
      response_hash = JSON.parse(res.body)
      tag_rule = ProjectRazor::Tagging::TagRule.new(response_hash['response'])

      tag_rule.uuid.should == @uuid
      tag_rule.tag_matchers.count.should == 1
      tag_rule.tag_matchers[0].class.should == ProjectRazor::Tagging::TagMatcher
      tag_rule.tag_matchers[0].key.should == "hostname"
      tag_rule.tag_matchers[0].value.should == "nick01"
      tag_rule.tag_matchers[0].compare.should == "equal"
      tag_rule.tag_matchers[0].inverse.should == "false"

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/matcher/add/#{@uuid}"
      json_hash = {}
      json_hash["@key"] = "ip_address"
      json_hash["@value"] = 'regex:^192.168.1.1[0-9][0-9]$'
      json_hash["@compare"] = "like"
      json_hash["@inverse"] = "true"
      json_string = JSON.generate(json_hash)
      res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
      response_hash = JSON.parse(res.body)
      tag_rule = ProjectRazor::Tagging::TagRule.new(response_hash['response'])

      tag_rule.uuid.should == @uuid
      tag_rule.tag_matchers.count.should == 2
      tag_rule.tag_matchers[1].class.should == ProjectRazor::Tagging::TagMatcher
      tag_rule.tag_matchers[1].key.should == "ip_address"
      tag_rule.tag_matchers[1].value.should == 'regex:^192.168.1.1[0-9][0-9]$'
      tag_rule.tag_matchers[1].compare.should == "like"
      tag_rule.tag_matchers[1].inverse.should == "true"
    end

    it "should be able to delete a tag matcher for a tag rule from REST" do

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/#{@uuid}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['response']['@uuid'].should == @uuid
      tag_rule = ProjectRazor::Tagging::TagRule.new(res_hash['response'])
      tag_rule.uuid.should == @uuid

      tag_rule.tag_matchers.count.should == 2

      tag_matcher = tag_rule.tag_matchers[0]
      tag_matcher.class.should == ProjectRazor::Tagging::TagMatcher

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/matcher/remove/#{@uuid}/#{tag_matcher.uuid}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      tag_rule = ProjectRazor::Tagging::TagRule.new(res_hash['response'])
      tag_rule.uuid.should == @uuid
      tag_rule.tag_matchers.count.should == 1
      tag_rule.tag_matchers[0].class.should == ProjectRazor::Tagging::TagMatcher
      tag_rule.tag_matchers[0].uuid.should_not == tag_matcher.uuid


    end




    it "should be able to delete a tag rule from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/#{@uuid}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['response']['@uuid'].should == @uuid

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/remove/#{@uuid}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['errcode'].should == 0

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/#{@uuid}"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      res_hash['response'].should == "TagRuleNotFound"
    end




    it "should be able to get all tag rules from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule/add"

      (1..10).each do
      |x|
        name = "test_tag_rule#{x}"
        tag = "RSPEC"

        json_hash = {}
        json_hash["@name"] = name
        json_hash["@tag"] = tag
        json_hash["@tag_matchers"] = []

        json_string = JSON.generate(json_hash)
        res = Net::HTTP.post_form(uri, 'json_hash' => json_string)
        response_hash = JSON.parse(res.body)

        response_hash['errcode'].should == 0
        response_hash['response']['@name'].should == name
        response_hash['response']['@tag'].should == tag
      end

      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      tag_rules = res_hash['response']
      tag_rules.count.should == 10
    end



    it "should be able to get all tag rules that match attributes from REST" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/tag/rule?@name=regex:test_tag_rule[3-5]"
      res = Net::HTTP.get(uri)
      res_hash = JSON.parse(res)
      tag_rules = res_hash['response']
      tag_rules[0]['@name'].should == "test_tag_rule3"
      tag_rules[1]['@name'].should == "test_tag_rule4"
      tag_rules[2]['@name'].should == "test_tag_rule5"
    end

  end

end