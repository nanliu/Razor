#!/usr/bin/env ruby
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"

require "node"
require "net/http"
require "json"
require "extlib"
require "colored"

uri = URI 'http://127.0.0.1:3000/razor/slice/node/query' # root URI for node slice actions

if ARGV.count > 0
  uuid = ARGV[0]
  uri = URI "#{uri}/one/#{uuid}"
else
  uri = URI "#{uri}/all"
end

res = Net::HTTP.get(uri)

node_hash_array = JSON.parse(res)
node_array = []
node_hash_array.each do
  |node_hash|
  node = Object::full_const_get(node_hash["@classname"]).new(node_hash)
  node_array << node
end

puts "Nodes:"
node_array.each do
  |node|

  print " UUID: "
  print "#{node.uuid}".green
  print " State: "
  print "#{node.last_state}".green
  print " Attributes "
  print "#{node.attributes_hash}".green
  print "\n"
end