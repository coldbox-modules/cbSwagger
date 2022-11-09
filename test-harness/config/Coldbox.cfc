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
			customErrorTemplate 	= "/coldbox/system/exceptions/Whoops.cfm",

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

		// Module Settings
		moduleSettings = {

			cbswagger : {
				//  The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
				// "routes":[ "api" ],
				// Information about your API
				"info"		:{
					// A title for your API
					"title" 			: "My Awesome API",
					// A descritpion of your API
					"description" 		: "This API produces amazing results and data.",
					// A terms of service URL for your API
					"termsOfService"	: "",
					//The contact email address
					"contact" 		:{
						"name": "API Support",
						"url": "http://www.swagger.io/support",
						"email": "info@ortussolutions.com"
					},
					//A url to the License of your API
					"license": {
						"name": "Apache 2.0",
						"url": "http://www.apache.org/licenses/LICENSE-2.0.html"
					},
					//The version of your API
					"version":"1.0.0"
				},
				"samplesPath"         : "/includes/resources",
				// Tags
				"tags" : [
					{
						"name": "pet",
						"description": "Pets operations"
					}
				],

				// https://swagger.io/specification/#serverObject
				"servers" : [
					{
						"url" 			: "https://mysite.com/v1",
						"description" 	: "The main production server"
					},
					{
						"url" 			: "http://127.0.0.1:60299",
						"description" 	: "The dev server"
					}
				],

				// An element to hold various schemas for the specification.
				// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#componentsObject
				"components" : {

					// Define your security schemes here
					// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securitySchemeObject
					"securitySchemes" : {
						"UserSecurity" : {
							// REQUIRED. The type of the security scheme. Valid values are "apiKey", "http", "oauth2", "openIdConnect".
							"type" 			: "http",
							// A short description for security scheme. CommonMark syntax MAY be used for rich text representation.
							"description" 	: "HTTP Basic auth",
							// REQUIRED. The name of the HTTP Authorization scheme to be used in the Authorization header as defined in RFC7235.
							"scheme" 		: "basic"
						},
						"APIKey" : {
							"type" 			: "apiKey",
							"description" 	: "An API key for security",
							"name" 			: "x-api-key",
							"in" 			: "header"
						}
					}
				},

				// A declaration of which security mechanisms can be used across the API.
				// The list of values includes alternative security requirement objects that can be used.
				// Only one of the security requirement objects need to be satisfied to authorize a request.
				// Individual operations can override this definition.
				"security" : [
					{ "APIKey" : [] },
					{ "UserSecurity" : [] }
				]
			}

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