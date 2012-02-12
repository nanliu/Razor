#!/usr/bin/env ruby
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
require "colored"

require "node" # not needed in this example yet
require "net/http"
require "json"

uri = URI 'http://127.0.0.1:8026/razor/slice/node/register' # root URI for node slice actions

if ARGV.count < 2
uuid = "TEST#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
state = "idle"
else
  uuid = ARGV[0]
  state = ARGV[1]
end


json_hash = {}
attributes_hash = {"hostname" => "nick01.example.com",
                   "ip_address" => "1.1.1.1"}
json_hash["@attributes_hash"] = attributes_hash
uri = URI "#{uri}/#{uuid}/#{state}"
res = Net::HTTP.post_form(uri, 'json_hash' => json_hash.to_json)
print "\nRegistered node:"
print" #{uuid}".green
print " at "
print "#{uri.to_s}\n".yellow
response_hash = JSON.parse(res.body)
print "Slice: "
print "#{response_hash['slice']}  ".green
print "Command: "
print "#{response_hash['command']}  ".green
print "Response: "
print "#{response_hash['result']}  ".green
print "\n"