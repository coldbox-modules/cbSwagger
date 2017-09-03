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
	property name="SESInterceptor"					inject="coldbox:interceptor:SES";
	property name="handlerService"					inject="coldbox:handlerService";
	property name="interceptorService"				inject="coldbox:interceptorService";
	property name="moduleService"					inject="coldbox:moduleService";

	// API Tools
	property name="OpenAPIUtil" 					inject="OpenAPIUtil@SwaggerSDK";
	property name="OpenAPIParser" 					inject="OpenAPIParser@SwaggerSDK";

	// Load upon loading
	property name="SESRoutes";

	/**
	* On DI Complete: Load up some services
	*/
	public function onDIComplete(){
		variables.interceptorService 	= variables.controller.getInterceptorService();
		variables.handlerService 		= variables.controller.getHandlerService();
		variables.SESRoutes 			= variables.SESInterceptor.getRoutes();
		variables.util 					= new coldbox.system.core.util.Util();
	}

	/**
	* Creates an OpenAPI Document from the Configured SES routes
	* @return swagger-sdk.models.OpenAPI.Document
	**/
	public any function createDocFromRoutes(){
		var template = getOpenAPIUtil().newTemplate();

		//append our configured settings
		for( var key in variables.cbSwaggerSettings ){
			if( structKeyExists( template, key ) ){
				template[ key ] = variables.cbSwaggerSettings[ key ];
			}
		}

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
			// if we have a module routing, retrieve those routes and append them to our loop
			if( len( route.moduleRouting ) ){
				var moduleRoutes = SESInterceptor.getModuleRoutes( route.moduleRouting );
				arrayAppend( moduleSESRoutes, duplicate( moduleRoutes ), true );
				continue;
			}
			for( var prefix in routingPrefixes ){
				if( !len( prefix ) || left( route.pattern, len( prefix ) ) == prefix ){
					designatedRoutes[ route.pattern ] = route;
				}
			}
		}

		// Now loop through our assembled module routes and append if designated
		for( var route in moduleSESRoutes ){
			var moduleConfigCache = variables.moduleService.getModuleConfigCache();
			if(
				structKeyExists( moduleConfigCache, route.module )
				&&
				structKeyExists( moduleConfigCache[ route.module ], "entrypoint" )
			){
				var moduleEntryPoint = arrayToList( listToArray( moduleConfigCache[ route.module ].entrypoint, "/" ), "/" );
				route.pattern = moduleEntryPoint & '/' & route.pattern;

				if( structKeyExists( moduleConfigCache[ route.module ], "cfmapping" ) ){
					route[ "moduleInvocationPath" ] = moduleConfigCache[ route.module ].cfmapping;
				} else {
					var moduleConventionPath = listToArray( variables.controller.getColdboxSettings().modulesConvention, "/" );
					arrayAppend( moduleConventionPath, route.module );
					route[ "moduleInvocationPath" ] = listToArray( moduleConventionPath, "." );
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
	* @param struct route  A coldbox SES Route Configuration
	**/
	private any function createPathsFromRouteConfig( required struct route ){
		var paths = createLinkedHashMap();
		//first parse our route to see if we have conditionals and create separate all found conditionals
		var pathArray 		= listToArray( getOpenAPIUtil().translatePath( arguments.route.pattern ), "/" );
		var assembledRoute 	= [];
		var handlerMetadata = getHandlerMetadata( arguments.route );

		for( var routeSegment in pathArray ){
			if( findNoCase( "?", routeSegment ) ){
				//first add the already assembled path
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
		//Add our final constructed route to the paths map
		addPathFromRouteConfig( paths, "/" & arrayToList( assembledRoute, "/" ), arguments.route );

		return paths;
	}


	/**
	* Creates paths individual paths from our routing configuration
	* @param java.util.LinkedHashMap existingPaths  		The existing path hashmap
	* @param string pathKey									The key of the path to be created
	* @param struct RouteConfig  							A coldbox SES Route Configuration
	* @param [ handlerMetadata ]							If not provided a lookup of the metadata will be performed
	**/
	private void function addPathFromRouteConfig(
		required any existingPaths,
		required string pathKey,
		required any routeConfig
		any handlerMetadata
	){
		var path = createLinkedHashmap();
		var errorMethods = [ 'onInvalidHTTPMethod', 'onMissingAction', 'onError' ];


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

						if( !isNull( arguments.handlerMetadata ) ){
							appendFunctionInfo( path[ lcase( methodName ) ], actions[ methodList ], arguments.handlerMetadata );
						}
					}
				}
			}
		} else{
			for( var methodName in getOpenAPIUtil().defaultMethods() ){
				path.put( lcase( methodName ), getOpenAPIUtil().newMethod() );
				if( len( actions ) && !isNull( arguments.handlerMetadata ) ){
					appendFunctionInfo( path[ lcase( methodName ) ], actions, arguments.handlerMetadata );
				}
			}
		}

		arguments.existingPaths.put( arguments.pathKey, path );
	}

	/**
	* Retreives the handler metadata, if available, from the route configuration
	* @param struct route  		A coldbox SES Route Configuration
	* @return any handlerMetadata
	**/
	private any function getHandlerMetadata( required any route ){
		var handlerRoute 	= ( isNull( arguments.route.handler ) ? "" : arguments.route.handler );
		var module 			= ( isNull( arguments.route.module ) ? "" : arguments.route.module );

		if( len( module ) && structKeyExists( arguments.route, "moduleInvocationPath" ) ){
			var invocationPath = arguments.route[ "moduleInvocationPath" ] & ".handlers." & handlerRoute;
		} else {
			var invocationPath = getHandlersInvocationPath() & "." & handlerRoute;
		}

		try{
			return util.getInheritedMetadata( invocationPath );
		} catch( any e ){
			return {};
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
		required any handlerMetadata
	){

		arguments.method[ "operationId" ] = arguments.functionName;

		var functionMetaData = getFunctionMetaData( arguments.functionName, arguments.handlerMetadata );

		if( !isNull( functionMetadata ) ){
			var defaultKeys = structKeyArray( arguments.method );
			for( var infoKey in functionMetaData ){
				if( findNoCase( "x-", infoKey ) ){
					var normalizedKey = replaceNoCase( infoKey, "x-", "" );
					//evaluate whether we have an x- replacement or a standard x-attribute
					if( arrayContains( defaultKeys, normalizedKey ) ){
						//check for $ref includes
						if(
							right( listFirst( functionMetaData[ infoKey ], "##" ), 5 ) == '.json'
							||
							left( functionMetaData[ infoKey ], 4 ) == 'http'
						){
							method[ normalizedKey ] = { "$ref" : replaceNoCase( functionMetaData[ infoKey ], "####", "##", "ALL" ) };
						} else {
							method[ normalizedKey ] = functionMetaData[ infoKey ];
						}

					} else {
						method[ infoKey ] = functionMetaData[ infoKey ];
					}
				} else if( arrayContains( defaultKeys, infoKey ) && isSimpleValue( functionMetadata[ infoKey ] ) ){
					//check for $ref includes
					if(
						right( listFirst( functionMetaData[ infoKey ], "##" ), 5 ) == '.json'
						||
						left( functionMetaData[ infoKey ], 4 ) == 'http'
					){
						method[ infoKey ] = { "$ref" : replaceNoCase( functionMetaData[ infoKey ], "####", "##", "ALL" ) };
					} else {
						method[ infoKey ] = functionMetaData[ infoKey ];
					}
				}
			}
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
