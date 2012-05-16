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
current_dir = File.dirname(File.expand_path(__FILE__))

lib_path = current_dir.sub(/\/bin$/,"/lib")
$LOAD_PATH.unshift(lib_path)
# We require the root lib
require 'project_razor'

class RazorDaemon < ProjectRazor::Object
  include Singleton

  def get_config
    get_data.config
  end

  def shutdown_instances
    # clean up before exiting
    puts "Shut down Node.js instances before exiting..."
  end

end

# define the directory to use for logging
log_dir = current_dir.sub(/\/bin$/,"/log")

def shutdown_instances
  # clean up before exiting
  razor_controller = RazorDaemon.instance
  razor_controller.shutdown_instances
end

options = {
    :ontop      => false,
    :multiple => false,
    :log_dir  => log_dir,
    :backtrace  => true,
    :log_output => true,
    :stop_proc => shutdown_instances
}

#Daemons.run("#{bin_dir}/razor_controller.rb", options)

Daemons.run_proc("razor_daemon", options) {

  # get a reference to the RazorDaemon instance
  razor_controller = RazorDaemon.instance
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
      puts "Check that mongodb instance is running and throw an error (and exit) if it is not"
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
}
