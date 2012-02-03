require "rspec"

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "rz_data"
require "fileutils"

PC_TIMEOUT = 3 # timeout for our connection to DB, using to make quicker tests
NODE_COUNT = 5 # total amount of nodes to use for node testing

def default_config
  RZConfiguration.new
end


def write_config(config)
  # First delete any existing default config
  File.delete(CONFIG_PATH) if File.exists?(CONFIG_PATH)
  # Now write out the default config above
  f = File.open(CONFIG_PATH, 'w+')
  f.write(YAML.dump(config))
  f.close
end



describe RZData do

  describe ".Configuration" do
    before(:all) do
      #Backup existing razor.conf being nice to the developer's environment
      FileUtils.mv(CONFIG_PATH, "#{CONFIG_PATH}.backup", :force => true) if File.exists?(CONFIG_PATH)
    end

    after(:all) do
      #Restore razor.conf back
      FileUtils.mv("#{CONFIG_PATH}.backup", CONFIG_PATH, :force => true) if File.exists?("#{CONFIG_PATH}.backup")
    end

    it "should load a config from config path(#{CONFIG_PATH}) on init" do
      config = default_config
      config.persist_host = "127.0.0.1"
      config.persist_mode = :mongo
      config.persist_port = 27017
      config.admin_port = (rand(1000)+1).to_s
      config.api_port = (rand(1000)+1).to_s
      config.persist_timeout = PC_TIMEOUT
      write_config(config)

      data = RZData.new

      # Check to make sure it is our config object
      data.config.admin_port.should == config.admin_port
      data.config.api_port.should == config.api_port


      # confirm the reverse that nothing is default
      data.config.admin_port.should_not == default_config.admin_port
      data.config.api_port.should_not == default_config.api_port

    end

    it "should create a default config object and new config file if there is none at default path" do
      # Delete the existing file
      File.delete(CONFIG_PATH) if File.exists?(CONFIG_PATH)
      File.exists?(CONFIG_PATH).should == false

      data = RZData.new

      # Confirm we have our default config
      data.config.instance_variables.each do
      |iv|
        # Loop and make sure each object matches
        data.config.instance_variable_get(iv).should == default_config.instance_variable_get(iv)
      end

      #Confirm we have our default file
      File.exists?(CONFIG_PATH).should == true
      data.persist_ctrl.teardown
    end

    it "should create a default config object if the YAML config has format errors" do
      temp_str = "--- !r*by/object:RZConfition\n\n\npersist_mode: :mongo\npersist_port: '27017'\nadmin_port: '8017'\ndddpersist_host: 127.0.0.1\ndddapi_port: '8026'\n"
      write_config(temp_str)
      File.exists?(CONFIG_PATH).should == true

      data = RZData.new

      # Confirm we have our default config
      data.config.instance_variables.each do
      |iv|
        # Loop and make sure each object matches
        data.config.instance_variable_get(iv).should == default_config.instance_variable_get(iv)
      end
      data.persist_ctrl.teardown
    end

    it "should create a default config object if the YAML config creates any nil instance variables because of malformed YAML" do
      temp_str = "--- !ruby/object:RZConfiguration\npersist_mode: :mongo\nDdDpersist_port: '27017'\ndDdadmin_port: '8017'\npersist_host: 127.0.0.1\napi_port: '8026'\n"
      write_config(temp_str)
      File.exists?(CONFIG_PATH).should == true

      data = RZData.new

      # Confirm we have our default config
      data.config.instance_variables.each do
      |iv|
        # Loop and make sure each object matches
        data.config.instance_variable_get(iv).should == default_config.instance_variable_get(iv)
      end
      data.persist_ctrl.teardown
    end

  end

  describe ".PersistenceController" do

    before(:all) do
      @data = RZData.new
    end

    after(:all) do
      @data.teardown
    end


    it "should create an Persistence Controller object with passed config" do
      @data.persist_ctrl.kind_of?(RZPersistController).should == true
    end

    it "should have an active Persistence Controller connection" do
      @data.persist_ctrl.is_connected?.should == true
    end

  end


  describe ".Nodes" do

    before(:all) do
      @data = RZData.new

      (1..NODE_COUNT).each do
      |x|
        temp_node = RZNode.new({:@name => "rspec_node_junk#{x}", :@last_state => :idle, :@current_state => :idle, :@next_state => :policy_applied})
        temp_node._persist_ctrl = @data.persist_ctrl
        @last_uuid = temp_node.uuid
        #(0..rand(10)).each do
        @data.persist_ctrl.object_hash_update(temp_node.to_hash, :node)
        #end
      end
    end

    after(:all) do
      @data.persist_ctrl.object_hash_remove_all(:node).should == true
      @data.teardown
    end

    it "should have a list of Nodes" do
      nodes = @data.fetch_all(:node)
      nodes.count.should == NODE_COUNT
    end

    it "should get a single node by UUID" do
      node = @data.fetch_by_uuid(:node, @last_uuid)
      node.is_a?(RZNode).should == true

      node = @data.fetch_by_uuid(:node, "12345")
      node.is_a?(NilClass).should == true
    end

    it "should be able to add a new Node (does not exist)" do

    end

    it "should be able to update Node attributes for existing Node" do
      node = @data.fetch_by_uuid(:node, @last_uuid)
      node.is_a?(RZNode).should == true
      node.attributes_hash = {:hostname => "nick_weaver", :ip_address => "1.1.1.1", :iq => 160}
      node.update_self
      node.attributes_hash["hostname"].should == "nick_weaver"
      node.attributes_hash["ip_address"].should == "1.1.1.1"
      node.attributes_hash["iq"].should == 160

      node_confirm = @data.fetch_by_uuid(:node, @last_uuid)
      node_confirm.is_a?(RZNode).should == true
      node_confirm.attributes_hash["hostname"].should == "nick_weaver"
      node_confirm.attributes_hash["ip_address"].should == "1.1.1.1"
      node_confirm.attributes_hash["iq"].should == 160
    end

    it "should be able to update the LastState for existing Node" do
      node = @data.fetch_by_uuid(:node, @last_uuid)
      node.is_a?(RZNode).should == true
      node.last_state = :nick
      node.update_self
      node.last_state.should == :nick

      node_confirm = @data.fetch_by_uuid(:node, @last_uuid)
      node_confirm.is_a?(RZNode).should == true
      node_confirm.last_state = :nick
    end

    it "should be able to update the CurrentState for existing Node" do
      node = @data.fetch_by_uuid(:node, @last_uuid)
      node.is_a?(RZNode).should == true
      node.current_state = :nick
      node.update_self
      node.current_state.should == :nick

      node_confirm = @data.fetch_by_uuid(:node, @last_uuid)
      node_confirm.is_a?(RZNode).should == true
      node_confirm.current_state = :nick
    end


    it "should be able to update the NextState for existing Node" do
      node = @data.fetch_by_uuid(:node, @last_uuid)
      node.is_a?(RZNode).should == true
      node.next_state = :nick
      node.update_self
      node.next_state.should == :nick

      node_confirm = @data.fetch_by_uuid(:node, @last_uuid)
      node_confirm.is_a?(RZNode).should == true
      node_confirm.next_state = :nick
    end

  end

end