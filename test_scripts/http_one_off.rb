#!/usr/bin/env ruby
$LOAD_PATH << "#{ENV['RAZOR_HOME']}/lib/common"
require "colored"

require "node" # not needed in this example yet
require "net/http"
require "json"

uri = URI 'http://127.0.0.1:8026/razor/slice/node/register' # root URI for node slice actions

#if ARGV.count < 2
#uuid = "TEST#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
#state = "idle"
#else
  uuid = "mk000C29291C95"
  state = "idle"
#end


#json_hash = {}
#attributes_hash = {"hostname" => "nick01.example.com",
#                   "ip_address" => "1.1.1.1"}
#json_hash["@attributes_hash"] = attributes_hash
json_hash_string = '{"@attributes_hash": {
        "kernelmajversion": "3.0",
        "rubysitedir": "/usr/local/lib/ruby/site_ruby/1.8",
        "network_eth0": "192.168.5.0",
        "netmask": "255.255.255.0",
        "interfaces": "dummy0,eth0,lo",
        "fqdn": "mk000C29291C95.localdomain",
        "is_virtual": "false",
        "netmask_lo": "255.0.0.0",
        "swapsize": "61.79 MB",
        "rubyversion": "1.8.7",
        "network_lo": "127.0.0.0",
        "sshdsakey": "AAAAB3NzaC1kc3MAAACBANH8llJwYhCDmdhug9klbFulbu7KY9PMmqh6q6JnbvlfD6b+XpsKjZe7ErKfXRxnrYwGLtc4RnrB3oDBbMDJvK0I0mhoGWI2vj3NBeNzlQnhPqbN5RLDIGmKTgbXfXcZU71QPcZUnVnfxpk3jDlngFdLIfW/fGBsXK2/weFhhFk5AAAAFQCDuK0tTAuA+ph+mDdDPKoIAhplzQAAAIEAi43nUg7ObEO5KgZNxTmkxSqWBgSarvtmkKa5yqbBK06NQ/iZ6BKG9nEEJ9kmBquWopHyGsmATobeqk0cjZXbyh+OX2fWLl/viGJiMF6K7XBmtYnlmYP0EXxutkc1VHHrOshO1YUghLbGJZzmyM5rcbf2jyZR7LS7uvXIynx820MAAACBAJS/dQLfiEQ+jayfE9tlnoYPK7y2ildvNF9Hwq2rBVPBk9N8G9xYiqydWjCefNGmVV1om+UvNk5dG4TFHiGhRJJZQM4kDrFRtT7DG+Uv7qHu6N+Fs9t7BGwWn1CREPJlIg1c8XHDadz0pYgx9PWfxFwGRPpM6JWDxc6eWXPhrvvq",
        "physicalprocessorcount": 1,
        "macaddress_eth0": "00:0C:29:29:1C:95",
        "architecture": "i386",
        "processor0": "Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz",
        "hardwareisa": "unknown",
        "sshecdsakey": "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNaf1l1mg0e6Aw4SXEMdkKaXXz7ZB7NYvqKhZk9+ipOcPoCBQK7XllXfVs9WPX0bTjGTGttOjBLhwpoBvw5wsKk=",
        "domain": "localdomain",
        "osfamily": "Linux",
        "virtual": "physical",
        "netmask_eth0": "255.255.255.0",
        "ps": "ps -ef",
        "ipaddress": "192.168.5.73",
        "kernel": "Linux",
        "operatingsystemrelease": "3.0.3-tinycore",
        "macaddress_dummy0": "D6:0A:93:76:6D:56",
        "sshrsakey": "AAAAB3NzaC1yc2EAAAADAQABAAABAQD1YLy1JpM9E0Ky7qVREJbqo4OrkKEWY8n/e08ZtGW7h3Pz+sBh3AkgiBC60EXCxV3spM52rk4oGjLca9bj0MXGmF5nHM2+yHjfdKJJ2zf/TzylhL/szq0lDcWdzTPtZqzENXE7fQFmtYKfhX6fOrEhIGEAgEi+5cTH1COwjetXVVQFJjbx+VcAlc1YLdCkFdQgdFrI4kmO2rqGqd8WONJEXDDS+AdDEVUojNczb3vQsL581y/1bOXAo/goeF98P+0vc/Zcb64I1oCZPHyiLyz7hrYmKC9MKGXkgqYZqCbvZh3mt2LZo/t2HYBz1qT44GBGDXiR1L3jbPBi+PZaJFUj",
        "swapfree": "61.79 MB",
        "kernelrelease": "3.0.3-tinycore",
        "ipaddress_lo": "127.0.0.1",
        "hardwaremodel": "i686",
        "selinux": "false",
        "timezone": "UTC",
        "operatingsystem": "Linux",
        "kernelversion": "3.0.3",
        "macaddress": "D6:0A:93:76:6D:56",
        "path": "/usr/local/sbin:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin",
        "id": "root",
        "processorcount": "1",
        "facterversion": "1.6.5",
        "hostname": "mk000C29291C95",
        "ipaddress_eth0": "192.168.5.73",
        "uniqueid": "7f0100"
    }
}'
uri = URI "#{uri}/#{uuid}/#{state}"
res = Net::HTTP.post_form(uri, 'json_hash' => json_hash_string)
#print "\nRegistered node:"
#print" #{uuid}".green
#print " at "
#print "#{uri.to_s}\n".yellow
puts json_hash_string
puts res.body
#response_hash = JSON.parse(res.body)
#print "Slice: "
#print "#{response_hash['slice']}  ".green
#print "Command: "
#print "#{response_hash['command']}  ".green
#print "Response: "
#print "#{response_hash['result']}  ".green
#print "\n"