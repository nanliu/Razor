# CLI control point
# Format will be 'razor [command] [args,args,args]'

# This adds Razor Common lib path to the load path for this child proc
$LOAD_PATH << "#{ENV['RAZOR_PATH']}lib/common"

