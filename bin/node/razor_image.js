// Node.js Endpoint for Razor Image Service

var memdisk = process.env.RAZOR_HOME + "/images/mk/memdisk";
var mk_iso = process.env.RAZOR_HOME + "/images/mk/rz_mk-image.iso";
var razor_bin = process.env.RAZOR_HOME + "/bin/razor -w"; // Set razor.rb path
var exec = require("child_process").exec; // create our exec object
var express = require('express'); // include our express libs
fs = require('fs');

app = express.createServer(); // our express server


app.get('/razor/image/mk',
    function(req, res) {
        res.writeHead(200, {'Content-Type': 'application/octet-stream'});
        var fileStream = fs.createReadStream(mk_iso);
        fileStream.pipe(res);
    });

app.get('/razor/image/memdisk',
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

// TODO Add catch for if razor.js is already running on port
// Start our server if we can get a valid config
function startServer(json_config) {
    config = JSON.parse(json_config);
    if (config['@imagesvc_port'] != null) {

        if (config['@base_mk'] != null) {
            mk_iso = process.env.RAZOR_HOME + "/images/mk/" + config['@base_mk'];
        }


        app.listen(config['@imagesvc_port']);
        console.log('Razor Image Service Web Server started and listening on:%s', app.address().port);
    } else {
        console.log("There is a problem with your Razor configuration. Cannot load config.")
    }
}


getConfig();