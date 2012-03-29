# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved


# Root ProjectRazor::Node namespace
# @author Nicholas Weaver
class ProjectRazor::Node < ProjectRazor::Object
  attr_accessor :name
  attr_accessor :attributes_hash
  attr_accessor :timestamp
  attr_accessor :last_state
  attr_accessor :current_state
  attr_accessor :next_state

  # init
  # @param hash [Hash]
  def initialize(hash)
    super()
    @_collection = :node
    @attributes_hash = {}
    from_hash(hash)
  end

  def tags
    # Dynamically return tags for this node
    engine = ProjectRazor::Engine.instance
    engine.node_tags(self)
  end

  # We override the to_hash to add the 'tags key/value for sharing node tags
  def to_hash
    hash = super
    hash['@tags'] = tags
    hash
  end

  def uuid=(new_uuid)
    @uuid = new_uuid.upcase
  end

  def print_header
    return "UUID", "Last Checkin", "Tags"
  end

  def print_items
    temp_tags = self.tags
    temp_tags = ["n/a"] if temp_tags == [] || temp_tags == nil
    return @uuid, Time.at(@timestamp).to_s, "[#{temp_tags.join(",")}]"
  end

  def line_color
    :white_on_black
  end

  def header_color
    :red_on_black
  end

  def print_attributes_hash
    begin
      self.class.const_get :NodeAttr
    rescue
      define_node_attr_class
    end

    attr_array = []
    @attributes_hash.each do
    |k,v|
      if v.to_s.length < 32
        attr_array << ProjectRazor::Node::NodeAttr.new(["Name", "Value"], [k.to_s, v.to_s], line_color, header_color)
      end
    end
    attr_array
  end

  def define_node_attr_class
    puts "Defining class"
    p = Class.new do
      def initialize(print_header, print_items, line_color, header_color)
        @print_header = print_header
        @print_items = print_items
        @line_color = line_color
        @header_color = header_color
      end

      attr_reader :print_header, :print_items, :line_color, :header_color

    end

    self.class.const_set :NodeAttr, p
  end
end
