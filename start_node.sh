#!/bin/bash
#
# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved
#

# Starts node server or restarts if running

killall -2 node
nohup node $RAZOR_HOME/bin/node/razor_api.js &
nohup node $RAZOR_HOME/bin/node/razor_image.js &