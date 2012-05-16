#!/usr/bin/env ruby
#
# A simple "wrapper" script that is used to daemonize the razor_control_server.rb
# script (which represents the primary Razor Controller) .  This wrapper script
# is used to start, stop, restart, etc. the underlying razor_control_server.rb
# script and could be replaced by a more standard, OS-specific mechanism later
# (perhaps)
#
# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved
#
# @author Tom McSweeney

require 'rubygems'
require 'daemons'

# add our the Razor lib path to the load path. This is for non-gem ease of use
bin_dir = File.dirname(File.expand_path(__FILE__))
log_dir = bin_dir.sub(/\/bin$/,"/log")

options = {
  :ontop      => false,
  :multiple => false,
  :log_dir  => log_dir,
  :backtrace  => true,
  :log_output => true
}

Daemons.run("#{bin_dir}/razor_controller.rb", options)