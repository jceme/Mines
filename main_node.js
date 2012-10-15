// Start tests

var requirejs = require("requirejs");

requirejs.config({
	baseUrl: "coffee",
    nodeRequire: require,
    paths: {
    	"cs": "../node_modules/cs/cs"
    }
});


var prog = process && process.argv[2] ? process.argv[2] : "testSolver";

requirejs(["cs!"+prog], function() { });
