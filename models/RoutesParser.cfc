/**
 * Copyright since 2016 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * ColdBox Route Parser
 */
component accessors="true" threadsafe singleton{

	// DI
	property name="controller" 						inject="coldbox";
	property name="cbSwaggerSettings" 				inject="coldbox:setting:cbswagger";
	property name="handlersPath" 					inject="coldbox:setting:HandlersPath";
	property name="handlersInvocationPath" 			inject="coldbox:setting:HandlersInvocationPath";
	property name="handlersExternalLocationPath" 	inject="coldbox:setting:HandlersExternalLocationPath";
	property name="handlerService"					inject="coldbox:handlerService";
	property name="interceptorService"				inject="coldbox:interceptorService";
	property name="moduleService"					inject="coldbox:moduleService";

	// API Tools
	property name="OpenAPIUtil" 					inject="OpenAPIUtil@SwaggerSDK";
	property name="OpenAPIParser" 					inject="OpenAPIParser@SwaggerSDK";

	/**
	 * Application SES Routes
	 */
	property name="SESRoutes" type="array";

	/**
	 * The appropriate routing service
	 */
	property name="routingService";

	/**
	 * Constructor
	 */
	function init(){
		return this;
	}

	/**
	 * On DI Complete: Load up some services
	 */
	function onDIComplete(){
		if( listFirst( controller.getSetting( "version", true ), "." ) gte 5 ){
			variables.routingService = variables.controller.getRoutingService();
		} else {
			variables.routingService = variables.interceptorService.getInterceptor( "ses" );
		}
		variables.SESRoutes = variables.routingService.getRoutes();
		variables.util = new coldbox.system.core.util.Util();
	}

	/**
	 * Creates an OpenAPI Document from the Configured SES routes
	 * @return swagger-sdk.models.OpenAPI.Document
	 **/
	any function createDocFromRoutes(){
		var template = getOpenAPIUtil().newTemplate();

		// append our configured settings
		variables.cbSwaggerSettings
			.filter( function( key, value ){
				return structKeyExists( template, key );
			} )
			.each( function( key, value ){
				template[ key ] = value;
			} );

		var apiRoutes = filterDesignatedRoutes();
		var pathKeys = structKeyArray( apiRoutes );

		for( var path in pathKeys ){
			template[ "paths" ].putAll( createPathsFromRouteConfig( apiRoutes[ path ] ) );
		}

		return getOpenAPIParser().parse( template ).getDocumentObject();

	}

	/**
	* Filters the designated routes as provided in the cbSwagger configuration
	**/
	private any function filterDesignatedRoutes(){
		var routingPrefixes = variables.cbSwaggerSettings.routes;
		// make a copy of our routes array so we can append it
		var SESRoutes 			= duplicate( variables.SESRoutes );
		var moduleSESRoutes 	= [];
		var designatedRoutes 	= {};

		for( var route in SESRoutes ){
			// if we have a module routing, retrieve those routes and append them to our loop and continue with the next route
			if( len( route.moduleRouting ) ){
				var moduleRoutes = routingService.getModuleRoutes( route.moduleRouting );
				arrayAppend( moduleSESRoutes, duplicate( moduleRoutes ), true );
				continue;
			}

			// process a normal route
			for( var prefix in routingPrefixes ){
				if( !len( prefix ) || left( route.pattern, len( prefix ) ) == prefix ){
					designatedRoutes[ route.pattern ] = route;
				}
			}
		}

		// Now loop through our assembled module routes and append if designated
		var moduleConfigCache 	= variables.moduleService.getModuleConfigCache();
		var moduleSettings 		= variables.controller.getSetting( "modules" );

		for( var route in moduleSESRoutes ){
			if(
				structKeyExists( moduleSettings, route.module )
				&&
				len( moduleSettings[ route.module ].entryPoint )
			){
				var moduleEntryPoint = moduleSettings[ route.module ].entryPoint;
				// Check if ColdBox 5 inherited entry points are available.
				if( moduleSettings[ route.module ].keyExists( "inheritedEntryPoint") ){
					moduleEntryPoint = moduleSettings[ route.module ].inheritedEntryPoint;
				}
				// TODO: not sure why Jon is doing this, ask him.
				var moduleEntryPoint = arrayToList( listToArray( moduleEntryPoint, "/" ), "/" );
				// Prefix the entry point to the patterns
				route.pattern = moduleEntryPoint & '/' & route.pattern;

				if( structKeyExists( moduleConfigCache[ route.module ], "cfmapping" ) && len( moduleConfigCache[ route.module ].cfmapping ) ){
					route[ "moduleInvocationPath" ] = moduleConfigCache[ route.module ].cfmapping;
				} else {
					var moduleConventionPath = listToArray( variables.controller.getColdboxSettings().modulesConvention, "/" );
					arrayAppend( moduleConventionPath, route.module );
					route[ "moduleInvocationPath" ] = arrayToList( moduleConventionPath, "." );
				}
			}

			for( var prefix in routingPrefixes ){
				if( !len( prefix ) || left( route.pattern, len( prefix ) ) == prefix ){
					designatedRoutes[ route.pattern ] = route;
				}
			}

		}

		// Now custom sort our routes alphabetically
		var entrySet 		= structKeyArray( designatedRoutes );
		var sortedRoutes 	= createLinkedHashMap();

		for( var i = 1; i <= arrayLen( entrySet ); i++ ){
			entrySet[ i ] = replace( entrySet[ i ], "/", "", "ALL" );
		}

		arraySort( entrySet, "textnocase", "asc" );

		for( var pathEntry in entrySet ){
			for( var routeKey in designatedRoutes ){
				if( replaceNoCase( routeKey, "/", "", "ALL" ) == pathEntry ){
					sortedRoutes.put( routeKey, designatedRoutes[ routeKey ] );
				}
			}
		}

		return sortedRoutes;
	}

	/**
	 * Creates paths individual paths from our routing configuration
	 *
	 * @route A coldbox SES Route Configuration
	 *
	 * @return linked map
	 **/
	private any function createPathsFromRouteConfig( required struct route ){
		var paths = createLinkedHashMap();
		// first parse our route to see if we have conditionals and create separate all found conditionals
		var pathArray 		= listToArray( getOpenAPIUtil().translatePath( arguments.route.pattern ), "/" );
		var assembledRoute 	= [];
		var handlerMetadata = getHandlerMetadata( arguments.route );

		for( var routeSegment in pathArray ){
			if( findNoCase( "?", routeSegment ) ){
				// first add the already assembled path
				addPathFromRouteConfig(
					existingPaths 	= paths,
					pathKey 		= "/" & arrayToList( assembledRoute, "/" ),
					RouteConfig 	= arguments.route,
					handlerMetadata = !isNull( handlerMetadata ) ? handlerMetadata : false
				);
				//now append our optional key to construct an extended path
				arrayAppend( assembledRoute, replace( routeSegment, "?", "" ) );
			} else {
				arrayAppend( assembledRoute, routeSegment );
			}
		}

		// Add our final constructed route to the paths map
		addPathFromRouteConfig( paths, "/" & arrayToList( assembledRoute, "/" ), arguments.route );

		return paths;
	}


	/**
	 * Creates paths individual paths from our routing configuration
	 *
	 * @existingPaths The existing path hashmap
	 * @pathKey The key of the path to be created
	 * @routeConfig A coldbox SES Route Configuration
	 * @handlerMetadata	If not provided a lookup of the metadata will be performed
	 **/
	private void function addPathFromRouteConfig(
		required any existingPaths,
		required string pathKey,
		required any routeConfig
		any handlerMetadata
	){
		var path = createLinkedHashmap();
		var errorMethods = [ 'onInvalidHTTPMethod', 'onMissingAction', 'routeNotFound', 'fourOhFour', 'onError' ];

		if( isNull( arguments.handlerMetadata ) || !isBoolean( arguments.handlerMetadata ) ){
			arguments.handlerMetadata = getHandlerMetadata( arguments.routeConfig );
		}

		var actions = structKeyExists( arguments.routeConfig, "action" ) ? arguments.routeConfig.action : "";

		if( isStruct( actions ) ){
			for( var methodList in actions  ){
				// handle any delimited method lists
				for( var methodName in listToArray( methodList ) ){
					// handle explicit SES workarounds
					if( !arrayFindNoCase( errorMethods, actions[ methodList ] ) ){

						path.put( lcase( methodName ), getOpenAPIUtil().newMethod() );

						appendPathParams( arguments.pathKey, path[ lcase( methodName ) ] );

						if( !isNull( arguments.handlerMetadata ) ){
							appendFunctionInfo(
								path[ lcase( methodName ) ],
								actions[ methodList ],
								arguments.handlerMetadata,
								len( arguments.routeConfig.module ) ? arguments.routeConfig.module : javacast( "null", "" )
							);
						}
					}
				}
			}

		} else{
			for( var methodName in getOpenAPIUtil().defaultMethods() ){
				path.put( lcase( methodName ), getOpenAPIUtil().newMethod() );

				appendPathParams( arguments.pathKey, path[ lcase( methodName ) ] );

				if( len( actions ) && !isNull( arguments.handlerMetadata ) ){
					appendFunctionInfo( path[ lcase( methodName ) ], actions, arguments.handlerMetadata );
				}
			}
		}

		// Strip out any typing placeholders in routes
		var pathSegments = listToArray( arguments.pathKey, "/" );
		var typingParams = [ "numeric", "alpha", "regex" ];
		for( var i = 1; i <= arrayLen( pathSegments ); i++ ){
			var typedParam = listToArray( mid( pathSegments[ i ], 2, len( pathSegments[ i ] ) - 2 ), "-" );
			if( arrayLen( typedParam ) > 1 ){
				for( var type in typingParams ){
					if( findNoCase( type, typedParam[ 2 ] ) ){
						pathSegments[ i ] =  "{" & typedParam[ 1 ] & "}";
						break;
					}
				}
			}
		}

		arguments.existingPaths.put( "/" & arrayToList( pathSegments, "/" ), path );

	}

	/**
	 * Appends the path-based paramters to a method
	 * @pathKey The path key ( route )
	 * @method The current path method object
	 **/
	private void function appendPathParams( required string pathKey, required struct method ){
		// handle any parameters in the url now
		var pathParams = arrayFilter( listToArray( arguments.pathKey, "/" ), function( segment ){
			return left( segment, 1 ) == "{";
		} );

		if( arrayLen( pathParams ) ){

			if( !structKeyExists( arguments.method, "parameters" ) ){
				arguments.method.put( "parameters", [] );
			}

			for( var urlParam in pathParams ){
				// parsing for param types in Coldbox Routes
				var paramSegments = listToArray( mid( urlParam, 2, len( urlParam ) - 2 ), "-" );
				var paramName = paramSegments[ 1 ];

				arrayAppend(
					arguments.method[ "parameters" ],
					{
						"name"       : paramName,
						"in"         : "path",
						"required"   : true,
						"type"       : parseSegmentType( paramSegments )
					}
				);
			}
		}
	}

	/**
	 * Parses the segment type in to a swagger param type
	 * https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/2.0.md#parameterObject
	 **/
	private string function parseSegmentType( required array paramSegments ){
		if( arrayLen( paramSegments ) == 1 ) return "string";

		switch( paramSegments[ 2 ] ){
			case "numeric":{
				return "integer";
			}
			case "regex":{
				return "object";
			}
			default:{
				return "string";
			}
		}

	}

	/**
	* Retreives the handler metadata, if available, from the route configuration
	* @param struct route  		A coldbox SES Route Configuration
	* @return any handlerMetadata
	**/
	private any function getHandlerMetadata( required any route ){
		var handlerRoute 	= ( isNull( arguments.route.handler ) ? "" : arguments.route.handler );
		var module 			= ( isNull( arguments.route.module ) ? "" : arguments.route.module );

		if( !len( handlerRoute ) ) return;

		if( len( module ) && structKeyExists( arguments.route, "moduleInvocationPath" ) ){
			var invocationPath = arguments.route[ "moduleInvocationPath" ] & ".handlers." & handlerRoute;
		} else {
			var invocationPath = getHandlersInvocationPath() & "." & handlerRoute;
		}

		try{

			return util.getInheritedMetadata( invocationPath );

		} catch( any e ){
			throw(
				type         = "cbSwagger.RoutesParse.handlerSyntaxException",
				message      = "The handler at #invocationPath# could not be parsed.  The error that occurred: #e.message#",
				extendedInfo = e.detail
			);
		}

	}

	/**
	* Appends the function info/metadata to the method hashmap
	* @param java.util.LinkedHashmap method 		The method hashmap to append to
	* @param string functionName					The name of the function to look up in the handler metadata
	* @param any handlerMetadata 					The metadata of the handler to reference
	* @return null
	**/
	private void function appendFunctionInfo(
		required any method,
		required string functionName,
		required any handlerMetadata,
		moduleName
	){


		if( !isNull( moduleName ) ){

			var operationPath = moduleName & ":" & listLast( handlerMetadata.name, "." );

		} else{

			var operationPath = listLast( handlerMetadata.name, "." );

		}

		arguments.method[ "operationId" ] = operationPath & "." & arguments.functionName;

		var functionMetaData = getFunctionMetaData( arguments.functionName, arguments.handlerMetadata );
		if( !isNull( functionMetadata ) ){
			var defaultKeys = structKeyArray( arguments.method );
			for( var infoKey in functionMetaData ){
				// automatically make hints our "description"
				if( !isSimpleValue( functionMetaData[ infoKey ] ) ) continue;
				var infoMetadata = parseMetadataValue( functionMetaData[ infoKey ] );

				// x-attributes and custom keys
				if( infoKey == "hint" ){
					method.put( "description", infoMetadata );
				}
				else if( left( infoKey, 2 ) == "x-" ){
					var normalizedKey = replaceNoCase( infoKey, "x-", "" );
					//evaluate whether we have an x- replacement or a standard x-attribute
					if( arrayContains( defaultKeys, normalizedKey ) ){
						method[ normalizedKey ] = infoMetadata;
					} else {
						method[ infoKey ] = infoMetadata;
					}
				}
				// parameter handling
				else if( left( infoKey, 6 ) == 'param-'){
					var paramName = right( infoKey, len( infoKey ) - 6 );

					if( !structKeyExists( method, "parameters" ) ){
						method.put( "parameters", [] );
					}

					// See if our parameter was already provided through URL parsing
					paramSearch = arrayFilter( method[ "parameters" ], function( item ){
						return item.name == paramName;
					} );

					if( arrayLen( paramSearch ) ){

						var parameter = paramSearch[ 1 ];

					} else {

						//name it with defaults
						var parameter = {
							"name"       : paramName,
							"in"         : "query",
							"required"   : false,
							"type"       : "string"
						};

					}


					if( isSimpleValue( infoMetadata ) ){
						parameter[ "description" ] = infoMetadata;
					} else {
						structAppend( parameter, infoMetadata );
					}

					arrayAppend(
						method[ "parameters" ],
						parameter
					);

				}
				// individual response handling
				else if( left( infoKey, 9 ) == 'response-'){
					var responseName = right( infoKey, len( infoKey ) - 9 );

					if( !structKeyExists( method, "responses" ) ){
						method.put( "responses", createLinkedHashmap() );
					}

					method[ "responses" ].put( responseName, createLinkedHashmap() );

					if( isSimpleValue( infoMetadata ) ){
						method[ "responses" ][ responseName ][ "description" ] = infoMetadata;
					} else {
						method[ "responses" ][ responseName ].putAll( infoMetadata );
					}
				}
				else if( arrayContains( defaultKeys, infoKey ) && isSimpleValue( functionMetadata[ infoKey ] ) ){
					//don't override any previously set convention assignments
					if( isSimpleValue( infoMetadata ) && len( infoMetadata ) ){
						method[ infoKey ] = infoMetadata;
					} else if( !isSimpleValue( infoMetadata ) ) {
						method[ infoKey ] = infoMetadata;
					}

				}
			}
		}

	}

	/**
	* Parses the metatdata values in to a valid swagger definition
	* @metadataText 	the text content of the metadata item
	**/
	private any function parseMetadataValue( required string metadataText ){

		arguments.metadataText = trim( arguments.metadataText );

		if( isJSON( metadataText ) ){
			var parsedMetadata = deserializeJSON( metadataText );
			//check our metadata for $refs
			if( isStruct( parsedMetadata ) ){
				for( var key in parsedMetadata ){
					parsedMetadata[ key ] = parseMetadataValue( parsedMetadata[ key ] );
				}
			}
			return parsedMetadata;
		} else if(
			right( listFirst( metadataText, "##" ), 5 ) == '.json'
			||
			left( metadataText, 4 ) == 'http'
		){
			return { "$ref" : replaceNoCase( metadataText, "####", "##", "ALL" ) };
		} else {
			return metadataText;
		}
	}

	/**
	* Retreives the handler metadata, if available
	* @param string functionName					The name of the function to look up in the handler metadata
	* @param any handlerMetadata 					The metadata of the handler to reference
	* @return struct|null
	**/
	private any function getFunctionMetadata(
		required string functionName,
		required any handlerMetadata
	){

		//exit out if we have no functions defined
		if( !structKeyExists( arguments.handlerMetadata, "functions" ) ) return;

		for( var functionMetadata in arguments.handlerMetadata.functions ){
			if( lcase( functionMetadata.name ) == lcase( arguments.functionName ) ){
				return functionMetadata;
			}
		}

		return;
	}
}
