require "log4r"

puts "loging tests with Log4r"
puts "DEBUG < INFO < WARN < ERROR < FATAL"
puts "..nick"
puts "\n"
logger = Log4r::Logger.new("#{ENV['RAZOR_HOME']}/log/test_log.log")