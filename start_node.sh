#!/bin/bash
# Starts node server or restarts if running

killall -2 node
nohup node $RAZOR_HOME/bin/node/razor_api.js &
nohup node $RAZOR_HOME/bin/node/razor_image.js &