component{

	// Configure ColdBox Application
	function configure(){

		// coldbox directives
		coldbox = {
			//Application Setup
			appName 				= "Module Tester",

			//Development Settings
			reinitPassword			= "",
			handlersIndexAutoReload = true,
			modulesExternalLocation = [],

			//Implicit Events
			defaultEvent			= "",
			requestStartHandler		= "",
			requestEndHandler		= "",
			applicationStartHandler = "",
			applicationEndHandler	= "",
			sessionStartHandler 	= "",
			sessionEndHandler		= "",
			missingTemplateHandler	= "",

			//Error/Exception Handling
			exceptionHandler		= "",
			onInvalidEvent			= "",
			customErrorTemplate 	= "/coldbox/system/includes/BugReport.cfm",

			//Application Aspects
			handlerCaching 			= false,
			eventCaching			= false
		};

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		environments = {
			development = "localhost,127\.0\.0\.1"
		};

		// Module Directives
		modules = {
			// An array of modules names to load, empty means all of them
			include = [],
			// An array of modules names to NOT load, empty means none
			exclude = []
		};

		//Register interceptors as an array, we need order
		interceptors = [
			 //SES
			 { class="coldbox.system.interceptors.SES" }
		];

		//LogBox DSL
		logBox = {
			// Define Appenders
			appenders = {
				files={class="coldbox.system.logging.appenders.RollingFileAppender",
					properties = {
						filename = "tester", filePath="/#appMapping#/logs"
					}
				}
			},
			// Root Logger
			root = { levelmax="DEBUG", appenders="*" },
			// Implicit Level Categories
			info = [ "coldbox.system" ]
		};

		cbswagger = {
			// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
			//"routes":[ "api" ],
			//A base path prefix for your API - leave blank if all routes are configured to the root of the site
			"basePath":"/api",
			//The API host
			"host":"www.ortussolutions.com",
			// Information about your API
			"info":{
				//The contact email address
				"contact":{
					"name": "API Support",
					"url": "http://www.swagger.io/support",
					"email": "info@ortussolutions.com"
				},
				//A title for your API
				"title":"CB Swagger Test",
				//A descritpion of your API
				"description":"The testing of the cb swagger module",
				//A url to the License of your API
				"license": {
					"name": "Apache 2.0",
					"url": "http://www.apache.org/licenses/LICENSE-2.0.html"
				},
				//A terms of service URL for your API
				"termsOfService":"",
				//The version of your API
				"version":"1.0.0"
			},
			//An array of all of the request body formats your your API is configured to consume
			"consumes": ["application/json","multipart/form-data","application/x-www-form-urlencoded"],
			//An array of all of the response body formats your API delivers
			"produces": ["application/json"]
		};


	}

	/**
	 * Load the Module you are testing
	 */
	function afterAspectsLoad( event, interceptData, rc, prc ){
		controller.getModuleService()
			.registerAndActivateModule(
				moduleName 		= request.MODULE_NAME,
				invocationPath 	= "moduleroot"
			);
	}

}