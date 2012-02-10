var razor_bin = process.env.RAZOR_HOME + "/bin/razor.rb -w"; // Set razor.rb path
var exec = require("child_process").exec; // create our exec object
var express = require('express'); // include our express libs

app = express.createServer(); // our express server
app.use(express.bodyParser()); // Enable body parsing for POST
// app.use(express.profiler()); // Uncomment for profiling to console
// app.use(express.logger()); // Uncomment for logging to console

app.get('/razor/slice/*',
    function(req, res) {
        args = req.path.split("/");
        args.splice(0,3);
        var args_string = getArguments(args);
        process.stdout.write('\033[2J\033[0;0H');
        exec(razor_bin + args_string, function (err, stdout, stderr) {
            res.send(stdout, 200, {"Content-Type": "json/application"});
        });
    });

app.post('/razor/slice/*',
    function(req, res) {
        args = req.path.split("/");
        args.splice(0,3);
        var json_data = "'" + req.param('json_hash', null) + "'";

        var args_string = getArguments(args);
        process.stdout.write('\033[2J\033[0;0H');
        console.log(args_string);
        console.log(razor_bin + args_string + json_data);
        exec(razor_bin + args_string + json_data, function (err, stdout, stderr) {
            res.send(stdout, 200, {"Content-Type": "json/application"});
        });
    });


app.get('/*',
    function(req, res) {

        switch(req.path)
        {
            case "/":
                res.send('404 Error: Bad Request', 404);
                break;
            case "/razor":
                res.send('404 Error: Bad Request(No module selected)', 404);
                break;
            case "/razor/slice":
                res.send('404 Error: Bad Request(No slice selected)', 404);
                break;
            default:
                res.send('404 Error: Bad Request', 404);
        }
    });

function getArguments(args_array) {
    var arg_string = " ";
    for (x = 0; x < args.length; x++) {
        arg_string = arg_string + args[x] + " "
    }
    return arg_string;
}

function getConfig() {
    exec(razor_bin + " config read", function (err, stdout, stderr) {
        startServer(stdout);
    });
}

function startServer(json_config) {
    config = JSON.parse(json_config);
    if (config['@api_port'] != null) {
    app.listen(config['@api_port']);
    console.log('Razor API Web Server started and listening on:%s', app.address().port);
    } else {
        console.log("There is a problem with your Razor configuration. Cannot load config.")
    }
}


getConfig();

