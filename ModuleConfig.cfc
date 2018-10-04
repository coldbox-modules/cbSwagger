/**
* Copyright since 2016 by Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* Module Config
*/
component{

	// Module Properties
	this.title 				= "cbswagger";
	this.author 			= "Jon Clausen <jon_clausen@silowebworks.com>";
	this.webURL 			= "https://github.com/coldbox-modules/cbSwagger";
	this.description 		= "A coldbox module to auto-generate Swagger API documentation from your configured routes";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "cbswagger";
	// Model Namespace
	this.modelNamespace		= "cbswagger";
	// CF Mapping
	this.cfmapping			= "cbswagger";
	// Auto-map models
	this.autoMapModels		= true;
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies		= [ "swagger-sdk" ];

	/**
	* Configure module
	*/
	function configure(){
		// SES Routes
		routes = [
			//Module Root Requests
			{ pattern="", handler="Main", action="index" },
			// Convention Route
			{ pattern=":handler/:action?" }
		];

	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		// parse parent settings
		parseParentSettings();

		// Add mixins
		binder.map( "RoutesParser@cbswagger" )
			.to( "#moduleMapping#.models.RoutesParser" )
			.mixins( '/SwaggerSDK/models/mixins/hashMap.cfm' );
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){

	}

	/**
	* Prepare settings
	*/
	private function parseParentSettings(){
		/**
		Sample Config:
		cbswagger = {
			// The location of the cbswaggered APIs, defaults to /models/resources
			routes = ["api"]
		};
		**/
		// Read parent application config
		var oConfig 		= controller.getSetting( "ColdBoxConfig" );
		var cbswaggerDSL	= oConfig.getPropertyMixin( "cbswagger", "variables", structnew() );
		var configStruct 	= controller.getConfigSettings();

		// Default Config Structure
		configStruct.cbswagger = {
			// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
			"routes"   : ["api"],
			// A base path prefix for your API - leave blank if all routes are configured to the root of the site
			"basePath" : "/",
			// The API host
			"host"     : "",
			// API Protocol, default to http/https
			"schemes"  : [ "https", "http" ],
			// Information about your API
			"info"     : {
				//The contact email address
				"contact"        : {
					"name"  : "",
					"url"   : "",
					"email" : ""
				},
				//A title for your API
				"title"          : "",
				//A descritpion of your API
				"description"    : "",
				//A url to the License of your API
				"license"        :{
					"name" 	: "",
					"url"	: ""
				},
				//A terms of service URL for your API
				"termsOfService" : "",
				//The version of your API
				"version"        : ""
			},
			//An array of all of the request body formats your your API is configured to consume
			"consumes" : [ "application/json", "multipart/form-data", "application/x-www-form-urlencoded" ],
			//An array of all of the response body formats your API delivers
			"produces" : [ "application/json" ]
		};

		// Append it
		structAppend( configStruct.cbswagger, cbswaggerDSL, true );
	}

}
