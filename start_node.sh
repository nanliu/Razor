#!/bin/bash
# Starts node server or restarts if running

$RAZOR_HOME/bin/node/node razor_api.js &
$RAZOR_HOME/bin/node/node razor_image.js &