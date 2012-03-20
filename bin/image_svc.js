// EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
// Copyright © 2012 EMC Corporation, All Rights Reserved
//
// Node.js Endpoint for ProjectRazor Image Service

var path;
var mk_iso;

var razor_bin = __dirname+ "/razor -w"; // Set project_razor.rb path
console.log(razor_bin);
var exec = require("child_process").exec; // create our exec object
var express = require('express'); // include our express libs
fs = require('fs');

app = express.createServer(); // our express server


app.get('/razor/image/mk*',
    function(req, res) {
        args = req.path.split("/");
        args.splice(0,3);
        var args_string = getArguments(args);
        if (args.length < 2) {
            args_string = args_string + "default "
        }

        exec(razor_bin + " imagesvc path " + args_string, function (err, stdout, stderr) {
            console.log(stdout);
            path = getPath(stdout);
        });

        if (path != null) {
            res.writeHead(200, {'Content-Type': 'application/octet-stream'});
            var fileStream = fs.createReadStream(path);
            fileStream.pipe(res);
        } else {
            res.send("Error", 404, {"Content-Type": "application/octet-stream"});
        }

    });



function getPath(json_string) {
    var response = JSON.parse(json_string);
    if (response['errcode'] == 0) {
        return response['result'];
    } else {
        return null
    }

}

function getConfig() {
    exec(razor_bin + " config read", function (err, stdout, stderr) {
        console.log(stdout);
        startServer(stdout);
    });
}

function getArguments(args_array) {
    var arg_string = " ";
    for (x = 0; x < args.length; x++) {
        arg_string = arg_string + args[x] + " "
    }
    return arg_string;
}

// TODO Add catch for if project_razor.js is already running on port
// Start our server if we can get a valid config
function startServer(json_config) {
    var config = JSON.parse(json_config);
//    memdisk = config['@image_svc_path']  + "/mk/memdisk";
//    mk_iso = config['@image_svc_path']  + "/mk/" + config['@base_mk'] ;

    if (config['@image_svc_port'] != null) {
        app.listen(config['@image_svc_port']);
        console.log('ProjectRazor Image Service Web Server started and listening on:%s', app.address().port);
//        console.log('Default MK path: ' + mk_iso)
//        console.log('Default memdisk path: ' + memdisk)
    } else {
        console.log("There is a problem with your ProjectRazor configuration. Cannot load config.")
    }
}


getConfig();