#!/usr/bin/env ruby

# this is RazorController class and script
#
# the Razor Controller script is started as a daemon process using
# the associated razor_daemon.rb script.  This script is responsible for
# starting and stopping the Node.js instances when it is started and stopped
# and also responsible for ensuring that these Node.js instances and the
# underlying (mongodb for now) database instance remain running while this
# script is running.  The database instance is assumed to be started and
# stopped remotely, this script only ensures that it remains running while
# the Razor server (i.e. the Node.js instances) are running
#
# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved
#
# @author Tom McSweeney

require 'singleton'

# add our the Razor lib path to the load path. This is for non-gem ease of use
lib_path = File.dirname(File.expand_path(__FILE__)).sub(/\/bin$/,"/lib")
$LOAD_PATH.unshift(lib_path)
# We require the root lib
require 'project_razor'

class RazorController < ProjectRazor::Object
  include Singleton

  def get_config
    get_data.config
  end

end

# get a reference to the RazorController instance
razor_controller = RazorController.instance
razor_config = razor_controller.get_config

# convert the sleep time to milliseconds (for calculation of time remaining in
# each iteration; this time will be accurate to the nearest millisecond)
msecs_sleep = razor_config.daemon_min_cycle_time * 1000;

# flag that is used to ensure razor_config is reloaded before each pass through the loop
is_first_iteration = true

# and enter the main event-handling loop
loop do

  begin

    # grab the current time (used for calculation of the wait time and for
    # determining whether or not to register the node if the facts have changed
    # later in the event-handling loop)
    t1 = Time.now

    # reload configuration from Razor if not the first time through the loop
    # (in which case the razor_config variable will be set to nil)
    unless is_first_iteration
      razor_config = razor_controller.get_config
      # adjust time to sleep it has changed since the last iteration
      msecs_sleep = razor_config.daemon_min_cycle_time * 1000;
    else
      is_first_iteration = false
    end

    # check that instances of critical services (Node.js and mongodb) are running
    puts "Check that Node.js instances are running and (re)start if needed"
    sleep(5)
    puts "Check that mongodb instance is running and (re)start if needed"
    sleep(2)

    # fire off an event (via a slice command?) to check timings on tasks
    puts "Fire off event to check timings"
    sleep(1)

    # check to see how much time has elapsed, sleep for the time remaining
    # in the msecs_sleep time window
    t2 = Time.now
    msecs_elapsed = (t2 - t1) * 1000
    if msecs_elapsed < msecs_sleep then
      secs_sleep = (msecs_sleep - msecs_elapsed)/1000.0
      puts "Time remaining: #{secs_sleep} seconds..."
      sleep(secs_sleep) if secs_sleep >= 0.0
    end

  rescue => e
    puts "An exception occurred: #{e.message}"
    # check to see how much time has elapsed, sleep for the time remaining
    # in the msecs_sleep time window
    t2 = Time.now
    msecs_elapsed = (t2 - t1) * 1000
    if msecs_elapsed < msecs_sleep then
      secs_sleep = (msecs_sleep - msecs_elapsed)/1000.0
      puts "Time remaining: #{secs_sleep} seconds..."
      sleep(secs_sleep) if secs_sleep >= 0.0
    end
  end

end