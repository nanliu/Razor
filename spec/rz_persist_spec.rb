require "rspec"

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_configuration"
require "rz_persist_controller"

describe RzPersistController do


  describe ".Initialize" do
    before(:each) do
      @config = RZConfiguration.new
      @config.persist_mode = :mongo
      @persist = RzPersistController.new(@config)
    end

    it "should create a PersistMongo object for .persist_obj if config persist_mode is :mongo" do
      @persist.persist_obj.class.should == RzPersistMongo
    end

    it "should have stored config object and it should match" do
      @persist.config.should == @config
    end

    it "should connect to database successfully using credentials in config"
    it "should disconnect from database successfully"
  end

  describe ".Model" do
    it "should add a Model to the Model collection"
    it "should read a Model from the Model collection"
    it "should return a array of Models from the Model collection"
    it "should remove a Model from the Model collection"
    it "should update an existing Model in the Model collection"
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