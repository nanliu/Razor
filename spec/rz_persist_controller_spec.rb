require "rspec"

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_configuration"
require "rz_persist_controller"
require "rz_model"
require "rz_rspec_matchers"
require "uuid"

RSpec.configure do |config|
  config.include(RZRSpecMatchers)
end

describe RZPersistController do
  before(:each) do
        @config = RZConfiguration.new
        @config.persist_mode = :mongo
        @persist = RZPersistController.new(@config)
  end

  after(:each) do
        @persist.teardown
  end

  describe ".Initialize" do
    it "should create a PersistMongo object for .database if config persist_mode is :mongo" do
      @persist.database.class.should == RZPersistDatabaseMongo
    end

    it "should have stored config object and it should match" do
      @persist.config.should == @config
    end

    it "should have established a connection on initialization" do
      @persist.is_connected?.should == true
    end

  end

  describe ".Connection" do
    it "should connect to DatabaseEngine successfully using details in config" do
      @persist.is_connected?.should == true
    end

    it "should disconnect from DatabaseEngine successfully when teardown called" do
      @persist.check_connection.should == true  # make sure we have it open
      @persist.teardown  # do teardown
      @persist.is_connected?.should_not == true  # should be false now
    end

    it "should reconnect should the connection drop/timeout" do
      @persist.check_connection.should == true  # make sure we have it open
      @persist.teardown  # do teardown to break connection
      @persist.is_connected?.should_not == true  # make sure it is not connected
      @persist.check_connection.should == true  # should reconnect
    end
  end

  describe ".DatabaseBinding" do
    before(:each) do
      @persist.check_connection
    end

    it "should select/connect/bind to Razor database within DatabaseEngine successfully" do
      @persist.database.is_db_selected?.should == true
    end
  end



  describe ".Model" do
    before(:all) do
      @new_uuid = UUID.new
      @model1 = RZModel.new({:@name => "rspec_modelname01", :@uuid => @new_uuid.to_s, :@locked => false, :@model_type => "base", :@values_hash => {"a" => "1"}})
      @model2 = RZModel.new({:@name => "rspec_modelname02", :@uuid => @new_uuid.to_s, :@locked => false, :@model_type => "base", :@values_hash => {"a" => "1"}})
      @model3 = RZModel.new({:@name => "rspec_modelname03", :@uuid => @new_uuid.to_s, :@locked => false, :@model_type => "base", :@values_hash => {"a" => "1"}})
    end

    it "should be able to add/update a Model to the Model collection" do

      @persist.object_hash_update(@model1.to_hash, :model)
      sleep(1)
      @persist.object_hash_update(@model2.to_hash, :model)
      sleep(1)
      @persist.object_hash_update(@model3.to_hash, :model)

      model_hash_array = @persist.object_hash_get_all(:model)
      # Check if model_hash_array contains a model with the 'uuid' that matches our '@new_uuid'
      model_hash_array.should keys_with_values_count_equals({"@uuid" => @new_uuid.to_s},1)
    end
    it "should see the last update to a Model in the collection" do
      flag = false
      model_hash_array = @persist.object_hash_get_all(:model)
      model_hash_array.should keys_with_values_count_equals({"@uuid" => @new_uuid.to_s, "@name" => "rspec_modelname03"},1)
    end
    it "should return a array of Models from the Model collection without duplicates" do
      model_hash_array = @persist.object_hash_get_all(:model)
      model_hash_array.should keys_with_values_count_equals({"@uuid" => @new_uuid.to_s},1)
    end
    it "should remove a Model from the Model collection" do
      @persist.object_hash_remove(@model3.to_hash, :model).should == true # should get positive return
      model_hash_array = @persist.object_hash_get_all(:model)
      model_hash_array.should keys_with_values_count_equals({"@uuid" => @new_uuid.to_s},0)
    end
  end

  describe ".Policy" do
    it "should add a Policy to the Policy collection"
    it "should read a Policy from the Policy collection"
    it "should return a array of Policy from the Policy collection"
    it "should remove a Policy from the Policy collection"
    it "should update an existing Policy in the Policy collection"
  end

  describe ".State" do
    describe ".LastState" do
      it "should read the LastState of a specific node"
      it "should set the LastState of a specific node"
      it "should get an array of nodes of a specific LastState"
      it "should get an array of all nodes LastState"
    end

    describe ".CurrentState" do
      it "should read the CurrentState of a specific node"
      it "should set the CurrentState of a specific node"
      it "should get an array of nodes of a specific CurrentState"
      it "should get an array of all nodes CurrentState"
    end

    describe ".NextState" do
      it "should read the NextState of a specific node"
      it "should set the NextState of a specific node"
      it "should get an array of nodes of a specific NextState"
      it "should get an array of all nodes NextState"
    end
  end
end