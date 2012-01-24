require "rspec"
require "../lib/common/rz_configuration"
require "../lib/common/rz_persist"

describe "RZPersist" do

  it "should create a PersistMongo object for .persist_obj if config persist_mode is :mongo" do
    config = RZConfiguration.new
    config.persist_mode = :mongo
    persist = RZPersist.new(config)
    persist.persist_obj.class.should == RzPersistMongo
  end

  it "should add a Model to the Model collection"
  it "should read a Model from the Model collection"
  it "should return a array of Models from the Model collection"
  it "should remove a Model from the Model collection"
  it "should update an existing Model in the Model collection"

  it "should add a Policy to the Policy collection"
  it "should read a Policy from the Policy collection"
  it "should return a array of Policy from the Policy collection"
  it "should remove a Policy from the Policy collection"
  it "should update an existing Policy in the Policy collection"

  it "should read the LastState of a specific node"
  it "should set the LastState of a specific node"
  it "should get an array of nodes of a specific LastState"
  it "should get an array of all nodes LastState"

  it "should read the CurrentState of a specific node"
  it "should set the CurrentState of a specific node"
  it "should get an array of nodes of a specific CurrentState"
  it "should get an array of all nodes CurrentState"

  it "should read the NextState of a specific node"
  it "should set the NextState of a specific node"
  it "should get an array of nodes of a specific NextState"
  it "should get an array of all nodes NextState"

end