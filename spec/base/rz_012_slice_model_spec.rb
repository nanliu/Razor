$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rspec"
require "net/http"
require "json"
require "data"

describe "Razor::Slice::Model" do

  describe ".RESTful Interface" do

    it "should get a list of models object types" do
      uri = URI "http://127.0.0.1:#{@config.api_port}/razor/api/model/type"

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

    it "should get a list of model objects"

  end

end