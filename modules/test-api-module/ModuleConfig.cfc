/**
*********************************************************************************
* Your Copyright
********************************************************************************
*/
component{

	// Module Properties
	this.title 				= "test-api-module";
	this.author 			= "Jon Clausen <jon_clausen@silowebworks.com>";
	this.webURL 			= "N/A";
	this.description 		= "A test api module for cbSwagger";
	this.version			= "0.0.1";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "api/v2";
	// Model Namespace
	this.modelNamespace		= "test-api-module";
	// CF Mapping
	this.cfmapping			= "test-api-module";
	// Auto-map models
	this.autoMapModels		= true;
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies		= [ ];

	/**
	* Configure module
	*/
	function configure(){
		
		// API Routing
		var defaultAPIActions = {
			"GET":"index",
			"POST":"add",
			"PUT":"onInvalidHTTPMethod",
			"PATCH":"onInvalidHTTPMethod",
			"DELETE":"onInvalidHTTPMethod"
		};
		var defaultEntityActions = {
			"GET":"get",
			"PUT":"update",
			"PATCH":"update",
			"DELETE":"delete"
		};


		// SES Routes
		routes = [			
			//Module API Routes
			{
				pattern:'users/login',
				handler:'Users',
				action:{"POST":"login","DELETE":"login"}
			},
			{
				pattern:'users/:id',
				handler:'Users',
				action:defaultEntityActions
			},
			{
				pattern:'users',
				handler:'Users',
				action:defaultAPIActions
			}
		];


	}

}
