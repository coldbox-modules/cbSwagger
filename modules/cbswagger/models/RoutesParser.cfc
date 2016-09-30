component name="RouteParser" accessors="true"{
	property name="Controller" inject="coldbox";
	property name="cbSwaggerSettings" inject="coldbox:setting:cbswagger";
	property name="HandlersPath" inject="coldbox:setting:HandlersPath";
	property name="HandlersInvocationPath" inject="coldbox:setting:HandlersInvocationPath";
	property name="HandlersExternalLocationPath" inject="coldbox:setting:HandlersExternalLocationPath";
	property name="OpenAPIUtil" inject="OpenAPIUtil@SwaggerSDK";
	property name="OpenAPIDocument" inject="OpenAPIDocument@SwaggerSDK";
	property name="HandlerService";
	property name="InterceptorService";
	property name="SESRoutes";

	public function onDIComplete(){
		setInterceptorService( getController().getInterceptorService() );
		setHandlerService( getController().getHandlerService() );
		setSESRoutes( getInterceptorService().getInterceptor("SES").getRoutes() );
	}

	/**
	* Creates an OpenAPI Document from the Configured SES routes
	**/
	public Document function createDocFromRoutes(){
		var template = getOpenAPIUtil().newTemplate();
		var moduleSettings = getCBSwaggerSettings();
		//append our configured settings
		for( var key in moduleSettings ){
			if( structKeyExists( template, key ) ){
				template[ key ] = moduleSettings[ key ];
			}
		}

		var apiRoutes = filterDesignatedRoutes();
		
		for( var path in apiRoutes ){
			template[ "paths" ].putAll( createPathsFromRouteConfig( apiRoutes[ path ] ) );
		}

		return getOpenAPIDocument().init( template );

	}

	/**
	* Filters the designated routes as provided in the cbSwagger configuration
	**/
	private any function filterDesignatedRoutes(){
		var routingPrefixes = getCBSwaggerSettings().routes;
		var SESRoutes = getSESRoutes();
		var designatedRoutes = {};

		for( var route in SESRoutes ){
			for( var prefix in routingPrefixes ){
				if( !len( prefix ) || left( route.pattern, len( prefix ) ) == prefix ){
					designatedRoutes[ route.pattern ] = route;
				}
			}
		}
		
		//Now custom sort our routes alphabetically
		var entrySet = structKeyArray( designatedRoutes );
		var sortedRoutes = createLinkedHashMap();

		for( var i=1; i<=arrayLen( entrySet ); i++ ){
			entrySet[ i ]=replace( entrySet[ i ], "/", "", "ALL" );
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
	* @param struct Route  		A coldbox SES Route Configuration
	**/
	private any function createPathsFromRouteConfig( required struct Route ){
		var paths = createLinkedHashMap();
		//first parse our route to see if we have conditionals and create separate all found conditionals
		var pathArray = listToArray( getOpenAPIUtil().translatePath( Route.pattern ), "/" );
		var assembledRoute = [];
		var handlerMetadata = getHandlerMetadata( Route );
		
		for( var routeSegment in pathArray ){
			if( findNoCase( "?", routeSegment ) ){
				//first add the already assembled path
				addPathFromRouteConfig( 
					existingPaths=paths, 
					pathKey="/" & arrayToList( assembledRoute, "/" ), 
					RouteConfig=Route,
					handlerMetadata= !isNull( handlerMetadata ) ? handlerMetadata : false
				);
				//now append our optional key to construct an extended path
				arrayAppend( assembledRoute, replace( routeSegment, "?" ) );
			} else {
				arrayAppend( assembledRoute, routeSegment );
			}
		}
		//Add our final constructed route to the paths map
		addPathFromRouteConfig( paths, "/" & arrayToList( assembledRoute, "/" ), Route );

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
		required any RouteConfig
		any handlerMetadata
	){
		var path = createLinkedHashmap();
		var errorMethods = [ 'onInvalidHTTPMethod', 'onMissingHandler', 'onError' ];


		if( isNull(handlerMetadata) || !isBoolean( handlerMetadata ) ){
			arguments.handlerMetadata = getHandlerMetadata( ARGUMENTS.RouteConfig );
		}

		var actions = structKeyExists( RouteConfig, "action" ) ? RouteConfig.action : "";

		if( isStruct( actions ) ){
			for( var methodList in actions  ){
				//handle any delimited method lists
				for( var methodName in listToArray( methodList ) ){
					//handle explicit SES workarounds
					if( !arrayFindNoCase( errorMethods, actions[ methodList ] ) ){
						path.put( ucase( methodName ), getOpenAPIUtil().newMethod() );
					
						if( !isNull( handlerMetadata ) ){
							
							appendFunctionInfo( path[ucase( methodName )], actions[ methodList ], handlerMetadata );

						}	
					}
				}
			}
		} else{
			for( var methodName in getOpenAPIUtil().defaultMethods() ){
				path.put( ucase( methodName ), getOpenAPIUtil().newMethod() );
				if( len( actions ) && !isNull( handlerMetadata ) ){
					appendFunctionInfo( path[ucase( methodName )], actions, handlerMetadata );
				}	
			}
		}
		
		ARGUMENTS.existingPaths.put( ARGUMENTS.pathKey, path );
	}
	
	/**
	* Retreives the handler metadata, if available, from the route configuration
	* @param struct Route  		A coldbox SES Route Configuration
	* @return any handlerMetadata
	**/
	private any function getHandlerMetadata( required any Route ){
		var handlerRoute = Route.handler;
		var module = Route.module;

		if( len( module ) ){
			handlerRoute = module & ":" & handlerRoute;
		}

		try{
			var invocationPath = getHandlersInvocationPath() & "." & handlerRoute;
			var handler = createObject( "component", invocationPath );
			return getMetadata( handler );	
		} catch( any e ){
		 	return;	
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

		method[ "operationId" ] = functionName;

		var functionMetaData = getFunctionMetaData( functionName, handlerMetadata );
		
		if( !isNull( functionMetadata ) ){						
			var defaultKeys = structKeyArray( method );
			for( var infoKey in functionMetaData ){
				if( findNoCase( "x-", infoKey ) ){
					normalizedKey = replaceNoCase( infoKey, "x-", "" );
					//evaluate whether we have an x- replacement or a standard x-attribute
					if( arrayContains( defaultKeys, normalizedKey ) ){
						method[ normalizedKey ] = functionMetaData[ infoKey ];
					} else {
						method[ infoKey ] = functionMetaData[ infoKey ];
					}
				} else if( arrayContains( defaultKeys, infoKey ) && isSimpleValue( functionMetadata[ infoKey ] ) ){
					method[ infoKey ] = functionMetaData[ infoKey ]
				}
			}
		}

	}

	/**
	* Retreives the handler metadata, if available
	* @param string functionName					The name of the function to look up in the handler metadata
	* @param any handlerMetadata 					The metadata of the handler to reference
	* @return any|null
	**/
	private any function getFunctionMetadata( 
		required string functionName, 
		required any handlerMetadata 
	){
		for( var functionMetadata in handlerMetadata.functions ){
			if( lcase(functionMetadata.name) == lcase(arguments.functionName) ){
				return functionMetadata;
			}		
		}

		return;
	}
}