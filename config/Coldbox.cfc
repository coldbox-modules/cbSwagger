component{

	// Configure ColdBox Application
	function configure(){

		// coldbox directives
		coldbox = {
			//Application Setup
			appName 				= "Development Shell",

			//Development Settings
			reinitPassword			= "",
			handlersIndexAutoReload = true,

			//Implicit Events
			defaultEvent			= "main.index",
			requestStartHandler		= "",
			requestEndHandler		= "",
			applicationStartHandler = "main.onAppInit",
			applicationEndHandler	= "",
			sessionStartHandler 	= "",
			sessionEndHandler		= "",
			missingTemplateHandler	= "",

			//Extension Points
			ApplicationHelper 				= "",
			coldboxExtensionsLocation 	= "",
			modulesExternalLocation		= [],
			pluginsExternalLocation 	= "",
			viewsExternalLocation		= "",
			layoutsExternalLocation 	= "",
			handlersExternalLocation  	= "",
			requestContextDecorator 	= "",

			//Error/Exception Handling
			exceptionHandler		= "",
			onInvalidEvent			= "",
			customErrorTemplate		= "/coldbox/system/includes/BugReport.cfm",

			//Application Aspects
			handlerCaching 			= false,
			eventCaching			= false,
			proxyReturnCollection 	= false
		};

		// custom settings
		settings = {
		};

		// Activate WireBox
		wirebox = { enabled = true, singletonReload=false };

		// Module Directives
		modules = {
			//Turn to false in production, on for dev
			autoReload = false
		};

		//LogBox DSL
		logBox = {
			// Define Appenders
			appenders = {
				files={class="coldbox.system.logging.appenders.RollingFileAppender",
					properties = {
						filename = "javaloader", filePath="/#appMapping#/logs"
					}
				}
			},
			// Root Logger
			root = { levelmax="DEBUG", appenders="*" },
			// Implicit Level Categories
			info = [ "coldbox.system" ]
		};

		//Register interceptors as an array, we need order
		interceptors = [
			//SES
			{class="coldbox.system.interceptors.SES",
			 properties={}
			}
		];

		cbswagger = {
			// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
			//"routes":[ "api" ],
			//A base path prefix for your API - leave blank if all routes are configured to the root of the site
			"basePath":"/api",
			//The API host
			"host":"https://www.ortussolutions.com",
			// Information about your API
			"info":{
				//The contact email address
				"contact":"info@ortussolutions.com",
				//A title for your API
				"title":"CB Swagger Test",
				//A descritpion of your API
				"description":"The testing of the cb swagger module",
				//A url to the License of your API
				"license":"Apache2",
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

}