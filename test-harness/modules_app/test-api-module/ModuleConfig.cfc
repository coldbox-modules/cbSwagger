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

	/**
	* Configure module
	*/
	function configure(){

		// API Routing
		defaultAPIActions = {
			"GET"   	= "index",
			"POST"  	= "add",
			"PUT"   	= "onInvalidHTTPMethod",
			"PATCH" 	= "onInvalidHTTPMethod",
			"DELETE"	= "onInvalidHTTPMethod"
		};

		defaultEntityActions = {
			"GET"   	= "get",
			"PUT"   	= "update",
			"PATCH" 	= "update",
			"DELETE"	= "delete"
		};


		// SES Routes
		routes = [
			//Module API Routes
			{
				pattern	= 'users/:userID/posts/:id-numeric',
				handler	= 'UserPosts',
				action 	= {
					"GET"    = "get" ,
					"POST"   = "update",
					"PATCH"  = "update",
					"DELETE" = "delete"
				}
			},
			{
				pattern	= 'users/login',
				handler	= 'Users',
				action 	= { "POST" = "login" , "DELETE" = "logout" }
			},
			{
				pattern 	= 'users/:id',
				handler 	= 'Users',
				action 		= defaultEntityActions
			},
			{
				pattern = 'users',
				handler = 'Users',
				action  = defaultAPIActions
			},
			{ pattern="/v1", moduleRouting="api-v1" },
			{ pattern="/:handler/:action?" }
		];

	}

}
