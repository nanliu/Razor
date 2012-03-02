// EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
// Copyright © 2012 EMC Corporation, All Rights Reserved
//
// Node.js Endpoint for ProjectRazor Image Service

var memdisk;
var mk_iso;

var razor_bin = __dirname+ "/razor -w"; // Set project_razor.rb path
console.log(razor_bin);
var exec = require("child_process").exec; // create our exec object
var express = require('express'); // include our express libs
fs = require('fs');

app = express.createServer(); // our express server


app.get('/project_razor/image/mk',
    function(req, res) {
        res.writeHead(200, {'Content-Type': 'application/octet-stream'});
        var fileStream = fs.createReadStream(mk_iso);
        fileStream.pipe(res);
    });

app.get('/project_razor/image/memdisk',
    function(req, res) {
        console.log("Called");
        res.writeHead(200, {'Content-Type': 'application/octet-stream'});
        var fileStream = fs.createReadStream(memdisk);
        fileStream.pipe(res);
    });


function getConfig() {
    exec(razor_bin + " config read", function (err, stdout, stderr) {
        console.log(stdout);
        startServer(stdout);
    });
}

// TODO Add catch for if project_razor.js is already running on port
// Start our server if we can get a valid config
function startServer(json_config) {
    var config = JSON.parse(json_config);
    memdisk = config['@image_svc_path']  + "/mk/memdisk";
    mk_iso = config['@image_svc_path']  + "/mk/" + config['@base_mk'] ;

    if (config['@imagesvc_port'] != null) {

        if (config['@base_mk'] != null) {
            mk_iso = process.env.RAZOR_HOME + "/images/mk/" + config['@base_mk'];
        }
        app.listen(config['@imagesvc_port']);
        console.log('ProjectRazor Image Service Web Server started and listening on:%s', app.address().port);
        console.log('Default MK path: ' + mk_iso)
    } else {
        console.log("There is a problem with your ProjectRazor configuration. Cannot load config.")
    }
}


getConfig();