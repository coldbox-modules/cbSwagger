/**
 * Copyright since 2016 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Module Config
 */
component {

	// Module Properties
	this.title              = "cbswagger";
	this.author             = "Jon Clausen <jon_clausen@silowebworks.com>";
	this.webURL             = "https://github.com/coldbox-modules/cbSwagger";
	this.description        = "A coldbox module to auto-generate Swagger API documentation from your configured routes";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup   = true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint         = "cbswagger";
	// Model Namespace
	this.modelNamespace     = "cbswagger";
	// CF Mapping
	this.cfmapping          = "cbswagger";
	// Auto-map models
	this.autoMapModels      = true;
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies       = [ "swagger-sdk" ];

	/**
	 * Configure module
	 */
	function configure(){
		settings = {
			// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
			"routes"        : [ "api" ],
			// Routes to exclude from the generated spec
			"excludeRoutes" : [],
			// The default output format, either json or yml
			"defaultFormat" : "json",
			// A convention route, relative to your app root, where request/response samples are stored ( e.g. resources/apidocs/responses/[module].[handler].[action].[HTTP Status Code].json )
			"samplesPath"   : "resources/apidocs",
			// Information about your API
			// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#infoObject
			"info"          : {
				// REQUIRED A title for your API
				"title"          : "My Awesome API",
				// A short description of the application. CommonMark syntax MAY be used for rich text representation.
				"description"    : "",
				// A URL to the Terms of Service for the API. MUST be in the format of a URL.
				"termsOfService" : "",
				// Contact information for the exposed API.
				"contact"        : {
					// The identifying name of the contact person/organization.
					"name"  : "",
					// The URL pointing to the contact information. MUST be in the format of a URL.
					"url"   : "",
					// The email address of the contact person/organization. MUST be in the format of an email address.
					"email" : ""
				},
				// License information for the exposed API.
				"license" : {
					// The license name used for the API.
					"name" : "",
					// A URL to the license used for the API. MUST be in the format of a URL.
					"url"  : ""
				},
				// REQUIRED. The version of the OpenAPI document (which is distinct from the OpenAPI Specification version or the API implementation version).
				"version" : "1.0.0"
			},
			// An array of Server Objects, which provide connectivity information to a target server. If the servers property is not provided, or is an empty array, the default value would be a Server Object with a url value of /.
			// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#serverObject
			"servers"      : [],
			// An element to hold various schemas for the specification.
			// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#componentsObject
			"components"   : {},
			// A declaration of which security mechanisms can be used across the API.
			// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securityRequirementObject
			"security"     : [],
			// A list of tags used by the specification with additional metadata.
			// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#tagObject
			"tags"         : [],
			// Additional external documentation.
			// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#externalDocumentationObject
			"externalDocs" : { "description" : "", "url" : "" }
		};

		// SES Routes
		router.route( "/" )
			.withHandler( "Main" )
			.toAction( { "GET": "index", "OPTIONS": "options" } );

		router.route( "/json" )
			.withHandler( "Main" )
			.toAction( { "GET": "json", "OPTIONS": "options" } );

		router.route( "/yml" )
			.withHandler( "Main" )
			.toAction( { "GET": "yml", "OPTIONS": "options" } );
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
	}

}
