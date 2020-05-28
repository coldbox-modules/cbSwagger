/**
 * Copyright since 2016 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * ColdBox Routes Parser for Swagger/OpenAPI Support
 */
component accessors="true" threadsafe singleton {

	// DI
	property name="controller"                   inject="coldbox";
	property name="moduleSettings"               inject="coldbox:moduleSettings:cbswagger";
	property name="handlersPath"                 inject="coldbox:setting:HandlersPath";
	property name="handlersInvocationPath"       inject="coldbox:setting:HandlersInvocationPath";
	property name="handlersExternalLocationPath" inject="coldbox:setting:HandlersExternalLocationPath";
	property name="handlerService"               inject="coldbox:handlerService";
	property name="interceptorService"           inject="coldbox:interceptorService";
	property name="moduleService"                inject="coldbox:moduleService";

	// API Tools
	property name="openAPIUtil"   inject="OpenAPIUtil@SwaggerSDK";
	property name="openAPIParser" inject="OpenAPIParser@SwaggerSDK";

	/**
	 * Application SES Routes
	 */
	property name="SESRoutes" type="array";

	/**
	 * The appropriate routing service according to ColdBox Version
	 */
	property name="routingService";

	/**
	 * Constructor
	 */
	function init() {
		return this;
	}

	/**
	 * On DI Complete: Load up some services
	 */
	function onDIComplete() {
		if ( listFirst( controller.getColdBoxSettings().version, "." ) gte 5 ) {
			variables.routingService = variables.controller.getRoutingService();
		} else {
			variables.routingService = variables.interceptorService.getInterceptor( "ses" );
		}
		variables.SESRoutes = variables.routingService.getRoutes();
		variables.util      = new coldbox.system.core.util.Util();
	}

	/**
	 * Creates an OpenAPI Document from the Configured SES routes
	 *
	 * @return swagger-sdk.models.OpenAPI.Document
	 **/
	any function createDocFromRoutes() {
		var template = getOpenAPIUtil().newTemplate();

		// append our configured settings
		variables.moduleSettings
			.filter( function( key, value ) {
				return structKeyExists( template, key );
			} )
			.each( function( key, value ) {
				template[ key ] = value;
			} );

		// Incorporate our API routes into the document
		filterDesignatedRoutes().each( function( key, value ) {
			template[ "paths" ].putAll( createPathsFromRouteConfig( value ) );
		} );

		// Build out the Open API Document object
		return getOpenAPIParser().parse( template ).getDocumentObject();
	}

	/**
	 * Filters the designated routes as provided in the cbSwagger configuration
	 */
	private any function filterDesignatedRoutes() {
		// make a copy of our routes array so we can append it
		var routingPrefixes  = variables.moduleSettings.routes;
		var SESRoutes        = duplicate( variables.SESRoutes );
		var moduleSESRoutes  = [];
		var designatedRoutes = {};

		for ( var route in SESRoutes ) {
			// if we have a module routing, retrieve those routes and append them to our loop and continue with the next route
			if ( len( route.moduleRouting ) ) {
				var moduleRoutes = routingService.getModuleRoutes( route.moduleRouting );
				arrayAppend(
					moduleSESRoutes,
					duplicate( moduleRoutes ),
					true
				);
				continue;
			}

			// process a normal route
			for ( var prefix in routingPrefixes ) {
				if ( !len( prefix ) || left( route.pattern, len( prefix ) ) == prefix ) {
					if ( !findNoCase( ":handler/", route.pattern ) ) {
						designatedRoutes[ route.pattern ] = route;
					}
				}
			}
		}

		// Now loop through our assembled module routes and append if designated
		var moduleConfigCache = variables.moduleService.getModuleConfigCache();
		var modulesSettings   = variables.controller.getSetting( "modules" );

		for ( var route in moduleSESRoutes ) {
			if (
				// module exists
				structKeyExists( modulesSettings, route.module )
				&&
				// and it has an entry point
				len( modulesSettings[ route.module ].entryPoint )
			) {
				var moduleEntryPoint = modulesSettings[ route.module ].entryPoint;
				// Check if ColdBox 5 inherited entry points are available.
				if ( modulesSettings[ route.module ].keyExists( "inheritedEntryPoint" ) ) {
					moduleEntryPoint = modulesSettings[ route.module ].inheritedEntryPoint;
				}
				// TODO: not sure why Jon is doing this, ask him.
				var moduleEntryPoint = arrayToList( listToArray( moduleEntryPoint, "/" ), "/" );
				// Prefix the entry point to the patterns
				route.pattern        = moduleEntryPoint & "/" & route.pattern;

				if (
					structKeyExists( moduleConfigCache[ route.module ], "cfmapping" ) && len(
						moduleConfigCache[ route.module ].cfmapping
					)
				) {
					route[ "moduleInvocationPath" ] = moduleConfigCache[ route.module ].cfmapping;
				} else {
					var moduleConventionPath = listToArray(
						variables.controller.getColdboxSettings().modulesConvention,
						"/"
					);
					arrayAppend( moduleConventionPath, route.module );
					route[ "moduleInvocationPath" ] = arrayToList( moduleConventionPath, "." );
				}
			}

			for ( var prefix in routingPrefixes ) {
				if ( !len( prefix ) || left( route.pattern, len( prefix ) ) == prefix ) {
					if ( !findNoCase( ":handler/", route.pattern ) ) {
						designatedRoutes[ route.pattern ] = route;
					}
				}
			}
		}

		// Remove any route excludes
		if ( !!arrayLen( moduleSettings.excludeRoutes ) ) {
			for ( var route in structKeyArray( designatedRoutes ) ) {
				if ( !!arrayFindNoCase( moduleSettings.excludeRoutes, route ) ) {
					structDelete( designatedRoutes, route );
				}
			}
		}

		// Now custom sort our routes alphabetically
		var entrySet     = structKeyArray( designatedRoutes );
		var sortedRoutes = structNew( "ordered" );

		for ( var i = 1; i <= arrayLen( entrySet ); i++ ) {
			entrySet[ i ] = replace( entrySet[ i ], "/", "", "ALL" );
		}

		arraySort( entrySet, "textnocase", "asc" );

		for ( var pathEntry in entrySet ) {
			for ( var routeKey in designatedRoutes ) {
				if ( replaceNoCase( routeKey, "/", "", "ALL" ) == pathEntry ) {
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
	private any function createPathsFromRouteConfig( required struct route ) {
		var paths           = structNew( "ordered" );
		// first parse our route to see if we have conditionals and create separate all found conditionals
		var pathArray       = listToArray( getOpenAPIUtil().translatePath( arguments.route.pattern ), "/" );
		var assembledRoute  = [];
		var handlerMetadata = getHandlerMetadata( arguments.route ) ?: false;

		for ( var routeSegment in pathArray ) {
			if ( findNoCase( "?", routeSegment ) ) {
				// first add the already assembled path
				addPathFromRouteConfig(
					existingPaths   = paths,
					pathKey         = "/" & arrayToList( assembledRoute, "/" ),
					routeConfig     = arguments.route,
					handlerMetadata = handlerMetadata
				);

				// now append our optional key to construct an extended path
				arrayAppend( assembledRoute, replace( routeSegment, "?", "" ) );
			} else {
				arrayAppend( assembledRoute, routeSegment );
			}
		}

		// Add our final constructed route to the paths map
		addPathFromRouteConfig(
			existingPaths   = paths,
			pathKey         = "/" & arrayToList( assembledRoute, "/" ),
			routeConfig     = arguments.route,
			handlerMetadata = handlerMetadata
		);

		return paths;
	}

	/**
	 * Creates paths individual paths from our routing configuration
	 *
	 * @existingPaths The existing path hashmap
	 * @pathKey The key of the path to be created
	 * @routeConfig A coldbox SES Route Configuration
	 * @handlerMetadata	The handler metadata corresponding to the route
	 **/
	private void function addPathFromRouteConfig(
		required any existingPaths,
		required string pathKey,
		required any routeConfig,
		any handlerMetadata
	) {
		var path         = structNew( "ordered" );
		var errorMethods = [
			"onInvalidHTTPMethod",
			"onMissingAction",
			"routeNotFound",
			"fourOhFour",
			"onError"
		];
		var actions = structKeyExists( arguments.routeConfig, "action" ) ? arguments.routeConfig.action : "";

		// This ensures that if there are verbs attached to a route, it shows up in the actions as a struct.
		// The ColdBox router allows a { "pattern": "/some/path", "event": "handler.action", "verbs": "get" } syntax.
		// We only want one code path, when possible, so we convert these to the equivalent action structs:
		// { "pattern": "/some/path", "handler": "handler", "action": { "get": "action" } }
		if ( !isStruct( actions ) && structKeyExists( arguments.routeConfig, "verbs" ) ) {
			var targetAction = len( arguments.routeConfig.event ) ? listLast( arguments.routeConfig.event, "." ) : arguments.routeConfig.action;
			actions          = arguments.routeConfig.verbs
				.listToArray()
				.reduce( function( acc, verb ) {
					acc[ verb ] = targetAction;
					return acc;
				}, {} );
		}

		if ( isStruct( actions ) ) {
			for ( var methodList in actions ) {
				// handle any delimited method lists
				for ( var methodName in listToArray( methodList ) ) {
					// method not in error methods
					if ( !arrayFindNoCase( errorMethods, actions[ methodList ] ) ) {
						// Create new path template
						path.put( lCase( methodName ), getOpenAPIUtil().newMethod() );
						// Append Params
						appendPathParams( pathKey = arguments.pathKey, method = path[ lCase( methodName ) ] );
						// Append Function metadata
						if ( !isNull( arguments.handlerMetadata ) ) {
							appendFunctionInfo(
								methodName      = methodName,
								method          = path[ lCase( methodName ) ],
								functionName    = actions[ methodList ],
								handlerMetadata = arguments.handlerMetadata,
								moduleName      = len( arguments.routeConfig.module ) ? arguments.routeConfig.module : javacast(
									"null",
									""
								)
							);
						}
					}
				}
			}
		} else {
			for ( var methodName in getOpenAPIUtil().defaultMethods() ) {
				// Insert path template for default method
				path.put( lCase( methodName ), getOpenAPIUtil().newMethod() );
				// Append Params
				appendPathParams( pathKey = arguments.pathKey, method = path[ lCase( methodName ) ] );
				// Append metadata
				if ( len( actions ) && !isNull( arguments.handlerMetadata ) ) {
					appendFunctionInfo(
						methodName      = methodName,
						method          = path[ lCase( methodName ) ],
						functionName    = actions,
						handlerMetadata = arguments.handlerMetadata
					);
				}
			}
		}

		// Strip out any typing placeholders in routes
		var pathSegments = listToArray( arguments.pathKey, "/" );
		var typingParams = [ "numeric", "alpha", "regex:" ];
		for ( var i = 1; i <= arrayLen( pathSegments ); i++ ) {
			var typedParam = listToArray(
				mid(
					pathSegments[ i ],
					2,
					len( pathSegments[ i ] ) - 2
				),
				"-"
			);
			if ( arrayLen( typedParam ) > 1 ) {
				for ( var type in typingParams ) {
					if ( findNoCase( type, typedParam[ 2 ] ) ) {
						pathSegments[ i ] = "{" & typedParam[ 1 ] & "}";
						break;
					}
				}
			}
		}

		arguments.existingPaths.put( "/" & arrayToList( pathSegments, "/" ), path );
	}

	/**
	 * Appends the path-based paramters to a method
	 *
	 * @pathKey The path key ( route )
	 * @method The current path method object
	 **/
	private void function appendPathParams( required string pathKey, required struct method ) {
		// Verify parameters array in the method definition
		if ( !structKeyExists( arguments.method, "parameters" ) ) {
			arguments.method.put( "parameters", [] );
		}

		// handle any parameters in the url now
		listToArray( arguments.pathKey, "/" )
			.filter( function( segment ) {
				return left( segment, 1 ) == "{";
			} )
			.each( function( urlParam ) {
				// parsing for param types in Coldbox Routes
				var paramSegments = listToArray(
					mid(
						arguments.urlParam,
						2,
						len( arguments.urlParam ) - 2
					),
					"-"
				);
				var paramName = paramSegments[ 1 ];

				arrayAppend(
					method[ "parameters" ],
					{
						"name"        : paramName,
						"description" : paramName,
						"in"          : "path",
						"required"    : true,
						"schema"      : {
							"type"    : parseSegmentType( paramSegments ),
							"default" : ""
						}
					}
				);
			} );
	}

	/**
	 * Parses the segment type in to a swagger param type
	 * https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#parameterObject
	 **/
	private string function parseSegmentType( required array paramSegments ) {
		if ( arrayLen( paramSegments ) == 1 ) return "string";

		switch ( paramSegments[ 2 ] ) {
			case "numeric": {
				return "integer";
			}
			case "regex": {
				return "object";
			}
			default: {
				return "string";
			}
		}
	}

	/**
	 * Retreives the handler metadata, if available, from the route configuration
	 *
	 * @route A ColdBox Route record
	 *
	 * @throws cbSwagger.RoutesParse.handlerSyntaxException
	 *
	 * @return struct of handlerMetadata
	 */
	private any function getHandlerMetadata( required any route ) {
		var handlerRoute = ( isNull( arguments.route.handler ) ? "" : arguments.route.handler );
		var module       = ( isNull( arguments.route.module ) ? "" : arguments.route.module );
		var fullEvent    = ( isNull( arguments.route.event ) ? "" : arguments.route.event );

		// Do event's first, if found, use it for the handler location
		if ( len( fullEvent ) ) {
			// remove last part which should be the action
			handlerRoute = replace(
				fullEvent,
				".#listLast( fullEvent, "." )#",
				""
			);
		}

		// If no handlers, back out nothing to see here folks
		if ( !len( handlerRoute ) ) return;

		// Discover via module or parent root
		if ( len( module ) && structKeyExists( arguments.route, "moduleInvocationPath" ) ) {
			var invocationPath = arguments.route[ "moduleInvocationPath" ] & ".handlers." & handlerRoute;
		} else {
			var invocationPath = getHandlersInvocationPath() & "." & handlerRoute;
		}

		try {
			return util.getInheritedMetadata( invocationPath );
		} catch ( any e ) {
			throw(
				type         = "cbSwagger.RoutesParse.handlerSyntaxException",
				message      = "The handler at #invocationPath# could not be parsed.  The error that occurred: #e.message#",
				extendedInfo = e.detail
			);
		}
	}

	/**
	 * Appends the function info/metadata to the method hashmap
	 *
	 * @methodName The method name in use
	 * @method The method hashmap to append to
	 * @functionName The name of the function to look up in the handler metadata
	 * @handlerMetadata The metadata of the handler to reference
	 * @moduleName The module name if any
	 *
	 */
	private void function appendFunctionInfo(
		required any methodName,
		required any method,
		required string functionName,
		required any handlerMetadata,
		moduleName
	) {
		var operationPath = "#arguments.methodName#>" & // verb
		( !isNull( arguments.moduleName ) ? moduleName & ":" : "" ) & // Module
		(
			!isNull( handlerMetadata.displayName ) && handlerMetadata.displayName != "Component" ? handlerMetadata.displayName : listLast(
				handlerMetadata.name,
				"."
			)
		); // Name

		arguments.method[ "operationId" ] = operationPath & "." & arguments.functionName;
		arguments.functionMetaData        = getFunctionMetaData( arguments.functionName, arguments.handlerMetadata );
		// Process function metadata
		if ( !isNull( arguments.functionMetadata ) ) {
			var defaultKeys = arguments.method.keyArray();

			appendFunctionParams( argumentCollection = arguments );
			appendFunctionResponses( argumentCollection = arguments );

			functionMetadata
				.keyArray()
				.each( function( infoKey ) {
					// is !simple, continue to next key
					if ( !isSimpleValue( functionMetaData[ infoKey ] ) ) continue;

					// parse values from each key
					var infoMetadata = parseMetadataValue( functionMetaData[ infoKey ] );

					// hint/description/summary
					if ( infoKey == "hint" ) {
						method.put( "description", infoMetadata );
						method.put( "summary", infoMetadata );
						continue;
					}

					// Request body: { description, required, content : {} } if simple, we just add it as required, with listed as content
					if ( left( infoKey, 12 ) == "requestBody" ) {
						method.put( "requestBody", structNew( "ordered" ) );

						if ( isSimpleValue( infoMetadata ) ) {
							method[ "requestBody" ][ "description" ] = infoMetadata;
							method[ "requestBody" ][ "required" ]    = true;
							method[ "requestBody" ][ "content" ]     = { "#infoMetadata#" : {} };
						} else {
							method[ "requestBody" ].putAll( infoMetadata );
						}
						continue;
					}

					// security
					if ( infoKey == "security" ) {
						if ( isSimpleValue( infoMetadata ) ) {
							// expect a list of pre-defined securitySchemes
							method[ "security" ] = listToArray( infoMetadata )
								.filter( function( security ) {
									return structKeyList( moduleSettings.components.securitySchemes ).find( security );
								} )
								.map( function( item ) {
									return { "#item#" : [] };
								} );
						} else {
							method[ "security" ] = infoMetadata;
						}
						continue;
					}

					// Spec Extensions x-{name}, must be in lowercase
					if ( left( infoKey, 2 ) == "x-" ) {
						var normalizedKey = replaceNoCase( infoKey, "x-", "" ).lcase();
						// evaluate whether we have an x- replacement or a standard x-attribute
						if ( arrayContainsNoCase( defaultKeys, normalizedKey ) ) {
							method[ normalizedKey ] = infoMetadata;
						} else {
							method[ infoKey.lcase() ] = infoMetadata;
						}
						continue;
					}

					if ( arrayContainsNoCase( defaultKeys, infoKey ) ) {
						// don't override any previously set convention assignments
						if ( isSimpleValue( infoMetadata ) && len( infoMetadata ) ) {
							method[ infoKey ] = infoMetadata;
						} else if ( !isSimpleValue( infoMetadata ) ) {
							method[ infoKey ] = infoMetadata;
						}
					}
				} );

			// check for a request body convention file
			if ( !method.keyExists( "requestBody" ) || structIsEmpty( method[ "requestBody" ] ) ) {
				sampleArgs = { "type" : "requestBody" };
				sampleArgs.append( arguments );
				appendConventionSamples( argumentCollection = sampleArgs );
			}
		}
	}

	private void function appendConventionSamples(
		required string type,
		required any methodName,
		required any method,
		required string functionName,
		required any handlerMetadata,
		required any functionMetadata,
		moduleName
	) {
		var conventionDirectory = controller.getAppRootPath() & arrayToList(
			listToArray( moduleSettings.samplesPath, "/" ),
			"/"
		);
		if ( !directoryExists( conventionDirectory ) ) return;

		if ( directoryExists( conventionDirectory & "/" & type ) ) {
			var availableFiles = directoryList(
				conventionDirectory & "/" & arguments.type,
				true,
				"path",
				"*",
				"name DESC",
				"file"
			);
			/**
			 * we accept the following conventions:
			 * 1. [handler].[methodName].json - all sample types
			 * 2. [moduleName].[handler].[methodName].json - all sample types
			 * 3. [handler].[methodName].[status code|default].json - status-code specific responses
			 * 4. [moduleName].[handler].[methodName].[status code|default].json - status-code specific responses
			 */
			if ( !isNull( moduleName ) ) {
				var filterString = arrayToList(
					[
						moduleName,
						listLast( handlerMetadata.name, "." ),
						methodName
					],
					"."
				);
			} else {
				var filterString = arrayToList( [ handlerMetadata.name, methodName ], "." );
			}

			availableFiles
				.filter( function( filePath ) {
					return findNoCase( filterString, replaceNoCase( filePath, conventionDirectory, "" ) );
				} )
				.each( function( filePath ) {
					var fileContent = fileRead( filePath );
					if ( isJSON( fileContent ) ) {
						var sampleData  = parseMetadataValue( fileContent );
						var descriptors = listToArray(
							replaceNoCase(
								replaceNoCase( filePath, filterString & ".", "" ),
								conventionDirectory & "/" & type & "/",
								""
							),
							"."
						);
						arrayDeleteAt( descriptors, descriptors.len() );
						if ( descriptors.len() ) {
							method[ type ][ arrayToList( descriptors, "-" ) ] = type == "responses" ? {
								"description"                   : "",
								"#fileGetMimeType( filePath )#" : sampleData
							} : sampleData;
						} else {
							method[ type ] = type == "responses" ? {
								"default" : {
									"description"                   : "",
									"#fileGetMimeType( filePath )#" : sampleData
								}
							} : sampleData;
						}
					}
				} );
		}
	}

	private void function appendFunctionParams(
		required any methodName,
		required any method,
		required string functionName,
		required any handlerMetadata,
		required any functionMetadata,
		moduleName
	) {
		functionMetadata
			.keyArray()
			.filter( function( key ) {
				return left( key, 6 ) == "param-";
			} )
			.each( function( infoKey ) {
				// parse values from each key
				var infoMetadata = parseMetadataValue( functionMetaData[ infoKey ] );
				// Get the param name
				var paramName    = right( infoKey, len( infoKey ) - 6 );

				// See if our parameter was already provided through URL parsing
				var paramSearch = arrayFilter( method[ "parameters" ], function( item ) {
					return item.name == paramName;
				} );

				if ( arrayLen( paramSearch ) ) {
					var parameter = paramSearch[ 1 ];
					if ( isSimpleValue( infoMetadata ) ) {
						parameter[ "description" ] = infoMetadata;
					} else {
						structAppend( parameter, infoMetadata );
					}
				} else {
					// Default Params
					var parameter = {
						"name"        : paramName,
						"description" : "",
						"in"          : "query",
						"required"    : false,
						"schema"      : { "type" : "string", "default" : "" }
					};

					if ( isSimpleValue( infoMetadata ) ) {
						parameter[ "description" ] = infoMetadata;
					} else {
						structAppend( parameter, infoMetadata );
					}

					arrayAppend( method[ "parameters" ], parameter );
				}
			} );

		sampleArgs = { "type" : "parameters" };
		sampleArgs.append( arguments );
		appendConventionSamples( argumentCollection = sampleArgs );
	}

	private void function appendFunctionResponses(
		required any methodName,
		required any method,
		required string functionName,
		required any handlerMetadata,
		required any functionMetadata,
		moduleName
	) {
		functionMetadata
			.keyArray()
			.filter( function( key ) {
				return left( key, 9 ) == "response-";
			} )
			.each( function( infoKey ) {
				// parse values from each key
				var infoMetadata = parseMetadataValue( functionMetaData[ infoKey ] );
				// get reponse name
				var responseName = right( infoKey, len( infoKey ) - 9 );

				method[ "responses" ].put( responseName, structNew( "ordered" ) );

				// Use simple value for description and content type
				if ( isSimpleValue( infoMetadata ) ) {
					method[ "responses" ][ responseName ][ "description" ] = infoMetadata;
					method[ "responses" ][ responseName ][ "content" ]     = { "#infoMetadata#" : {} };
				} else {
					method[ "responses" ][ responseName ].putAll( infoMetadata );
				}
			} );

		sampleArgs = { "type" : "responses" };
		sampleArgs.append( arguments );
		appendConventionSamples( argumentCollection = sampleArgs );
	}

	/**
	 * Parses the metatdata values in to a valid swagger definition:
	 * - If JSON, it inflates it back
	 * - If .json or http value, then treat it as a $ref
	 * - Else just string
	 *
	 * @metadataText The text content of the metadata item
	 */
	private any function parseMetadataValue( required string metadataText ) {
		arguments.metadataText = trim( arguments.metadataText );
		var supportedExtensions = [ 'json', 'yaml', 'yml' ];

		if ( isJSON( metadataText ) ) {
			var parsedMetadata = deserializeJSON( metadataText );
			// check our metadata for $refs
			if ( isStruct( parsedMetadata ) ) {
				for ( var key in parsedMetadata ) {
					if ( isSimpleValue( parsedMetadata[ key ] ) ) {
						parsedMetadata[ key ] = parseMetadataValue( parsedMetadata[ key ] );
					}
				}
			}
			return parsedMetadata;
		} else if (
			supportedExtensions.contains( lcase( listLast( listFirst( metadataText, "##" ), '.' ) ) )
			||
			left( metadataText, 4 ) == "http"
		) {
			// Check if we have the root ~ delimiter for the resources convention
			if ( left( metadataText, 1 ) == "~" ) {
				metadataText = metadataText.replace( "~", moduleSettings.samplesPath & "/" );
			}
			return { "$ref" : replaceNoCase( metadataText, "####", "##", "ALL" ) };
		} else {
			return metadataText;
		}
	}

	/**
	 * Retreives the handler metadata, if available
	 *
	 * @functionName The name of the function to look up in the handler metadata
	 * @handlerMetadata The metadata of the handler to reference
	 *
	 * @return struct|null
	 */
	private any function getFunctionMetadata( required string functionName, required any handlerMetadata ) {
		// exit out if we have no functions defined
		if ( !structKeyExists( arguments.handlerMetadata, "functions" ) ) return;

		for ( var functionMetadata in arguments.handlerMetadata.functions ) {
			if ( lCase( functionMetadata.name ) == lCase( arguments.functionName ) ) {
				return functionMetadata;
			}
		}

		return;
	}

}
