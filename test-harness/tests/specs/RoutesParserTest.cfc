component
	extends   ="coldbox.system.testing.BaseTestCase"
	appMapping="/"
	accessors =true
{

	property name="wirebox"    inject="wirebox";
	property name="controller" inject="coldbox";

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll() {
		structDelete( application, "cbController" );
		structDelete( application, "wirebox" );

		super.beforeAll();

		// Wire up this object
		application.wirebox.autowire( this );
		variables.testHandlerMetadata = getMetadata( createObject( "component", "handlers.api.v1.Users" ) );
		variables.cbSwaggerSettings   = controller.getSetting( "modules" ).cbSwagger.settings;

		variables.model       = prepareMock( Wirebox.getInstance( "RoutesParser@cbSwagger" ) );
		variables.samplesPath = controller.getAppRootPath() & variables.model.getModuleSettings().samplesPath;

		// make all of our private model methods public
		var privateMethods = getMetadata( variables.model ).functions
			.filter( function( fn ) {
				return fn.keyExists( "access" ) && fn.access == "private";
			} )
			.map( function( fn ) {
				return fn.name;
			} );
		privateMethods.each( function( methodName ) {
			makePublic(
				variables.model,
				methodName,
				methodName
			);
		} );
	}

	function afterAll() {
		// do your own stuff here
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run() {
		describe( "Tests core RouteParser Methods", function() {
			beforeEach( function( currentSpec ) {
				setup();
			} );

			afterEach( function( currentSpec ) {
				if ( !variables.keyExists( "model" ) ) return;

				if ( directoryExists( variables.samplesPath ) ) {
					directoryDelete( samplesPath, true );
				}
			} );

			it( "Tests the creation document generated by createDocFromRoutes", function() {
				expect( variables.model ).toBeComponent();

				var APIDoc = variables.model.createDocFromRoutes();
				expect( APIDoc ).toBeComponent();

				var NormalizedDoc = APIDoc.getNormalizedDocument();

				expect( NormalizedDoc ).toBeStruct();
				expect( NormalizedDoc )
					.toHaveKey( "openapi" )
					.toHaveKey( "info" )
					.toHaveKey( "servers" )
					.toHaveKey( "paths" )
					.toHaveKey( "components" )
					.toHaveKey( "security" )
					.toHaveKey( "tags" )
					.toHaveKey( "externalDocs" );

				expect( isJSON( APIDoc.asJSON() ) ).toBeTrue();

				variables.APIDoc = APIDoc;
			} );

			it( "Tests casting", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				var doc = APIDoc.getNormalizedDocument();

				expect( doc ).toBeStruct();
				expect( doc ).toHaveKey( "paths" );

				for ( var pathKey in doc[ "paths" ] ) {
					if ( left( pathKey, 2 ) == "x-" ) continue;

					for ( var methodKey in doc[ "paths" ][ pathKey ] ) {
						if ( left( methodKey, 2 ) == "x-" ) continue;

						var method = doc[ "paths" ][ pathKey ][ methodKey ];
						expect( method ).toBeStruct();
						if ( structKeyExists( method, "parameters" ) ) {
							expect( method[ "parameters" ] ).toBeArray();
						}
					}
				}
			} );

			it( "Tests the API Document against the routing configuration", function() {
				var swaggerUtil = wirebox.getInstance( "OpenAPIUtil@SwaggerSDK" );
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				var normalizedDoc = variables.APIDoc.getNormalizedDocument();
				expect( normalizedDoc ).toHaveKey( "paths" );

				var APIPaths    = normalizedDoc[ "paths" ];
				// pull our routing configuration
				var apiPrefixes = cbSwaggerSettings.routes;
				expect( apiPrefixes ).toBeArray();

				var CBRoutes = getController()
					.getInterceptorService()
					.getInterceptor( "SES" )
					.getRoutes();
				expect( CBRoutes ).toBeArray();

				expect( arrayLen( CBRoutes ) ).toBeGT( 0 );

				// Tests that all of our configured paths exist
				for ( var routePrefix in apiPrefixes ) {
					for ( var route in cbRoutes ) {
						if ( left( route.pattern, len( routePrefix ) ) == routePrefix ) {
							var translatedPath = swaggerUtil.translatePath( route.pattern );
							if ( !len( route.moduleRouting ) ) {
								expect( normalizedDoc[ "paths" ] ).toHaveKey( translatedPath );
							}
						}
					}
				}
			} );

			it( "Tests the API Document for module introspection", function() {
				var swaggerUtil = Wirebox.getInstance( "OpenAPIUtil@SwaggerSDK" );
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				var normalizedDoc = variables.APIDoc.getNormalizedDocument();
				expect( normalizedDoc ).toHaveKey( "paths" );

				var APIPaths    = normalizedDoc[ "paths" ];
				// pull our routing configuration
				var apiPrefixes = cbSwaggerSettings.routes;
				expect( apiPrefixes ).toBeArray();

				var TLRoutes = getController()
					.getInterceptorService()
					.getInterceptor( "SES" )
					.getRoutes();
				expect( TLRoutes ).toBeArray();

				expect( arrayLen( TLRoutes ) ).toBeGT( 0 );

				for ( var TLRoute in TLRoutes ) {
					if ( len( TLRoute.moduleRouting ) ) {
						var CBRoutes = getController()
							.getInterceptorService()
							.getInterceptor( "SES" )
							.getModuleRoutes( TLRoute.moduleRouting );

						// Tests that all of our configured paths exist
						for ( var routePrefix in apiPrefixes ) {
							// recurse into the module routes
							for ( var route in CBRoutes ) {
								if ( left( route.pattern, len( routePrefix ) ) == routePrefix ) {
									var translatedPath = swaggerUtil.translatePath( route.pattern );
									expect( normalizedDoc[ "paths" ] ).toHaveKey( translatedPath );
								}
							}
						}
					}
				}
			} );

			it( "Tests that route-based parameters are appended to all method params", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				var normalizedDoc = variables.APIDoc.getNormalizedDocument();

				expect( normalizedDoc ).toHaveKey( "paths" );
				expect( normalizedDoc[ "paths" ] ).toHaveKey( "/api/v1/users/{id}" );
				expect( normalizedDoc[ "paths" ][ "/api/v1/users/{id}" ] ).toBeStruct();

				var path = normalizedDoc[ "paths" ][ "/api/v1/users/{id}" ];

				for ( var methodKey in path ) {
					if ( isSimpleValue( path[ methodKey ] ) ) continue;

					expect( path[ methodKey ] ).toHaveKey( "parameters" );

					var idParamSearch = arrayFilter( path[ methodKey ][ "parameters" ], function( parameter ) {
						return ( structKeyExists( parameter, "name" ) && parameter[ "name" ] == "id" );
					} );


					expect( arrayLen( idParamSearch ) ).toBe( 1 );

					expect( idParamSearch[ 1 ].required ).toBeTrue();
					expect( idParamSearch[ 1 ][ "in" ] ).toBe( "path" );
				}
			} );

			it( "Tests the ability to parse parameter metadata definitions", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				var normalizedDoc = variables.APIDoc.getNormalizedDocument();

				expect( normalizedDoc ).toHaveKey( "paths" );
				expect( normalizedDoc[ "paths" ] ).toHaveKey( "/api/v1/users/{id}" );
				expect( normalizedDoc[ "paths" ][ "/api/v1/users/{id}" ] );

				var path = normalizedDoc[ "paths" ][ "/api/v1/users/{id}" ];

				expect( path ).toHaveKey( "put" );

				expect( path[ "put" ] ).toHaveKey( "parameters" );

				var firstNameSearch = arrayFilter( path[ "put" ][ "parameters" ], function( parameter ) {
					return structKeyExists( parameter, "name" ) && parameter[ "name" ] == "firstname";
				} );

				expect( arrayLen( firstNameSearch ) ).toBe( 1 );

				expect( firstNameSearch[ 1 ] ).toBeStruct().toHaveKey( "required" );

				expect( firstNameSearch[ 1 ].required ).toBe( false );
			} );


			it( "Tests the ability to parse response metadata definitions", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				var normalizedDoc = variables.APIDoc.getNormalizedDocument();

				expect( normalizedDoc ).toHaveKey( "paths" );
				expect( normalizedDoc[ "paths" ] ).toHaveKey( "/api/v1/users/{id}" );
				expect( normalizedDoc[ "paths" ][ "/api/v1/users/{id}" ] );

				var path = normalizedDoc[ "paths" ][ "/api/v1/users/{id}" ];

				expect( path ).toHaveKey( "put" );

				expect( path[ "put" ] ).toHaveKey( "responses" );
				expect( path[ "put" ][ "responses" ] ).toHaveKey( "default" );

				expect( path[ "put" ][ "responses" ][ "default" ] ).toBeStruct().toHaveKey( "description" );

				expect( path[ "put" ][ "responses" ][ "default" ][ "description" ] ).toBe( "User successfully updated" );

				expect( path[ "put" ][ "responses" ][ "default" ][ "content" ] ).toBeStruct();
			} );

			it( "Verifies that path typing parameters are removed and that the key omits the type", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );
				expect( variables ).toHaveKey( "samplesPath" );

				var normalizedDoc = variables.APIDoc.getNormalizedDocument();

				expect( normalizedDoc ).toHaveKey( "paths" );
				expect( normalizedDoc[ "paths" ] ).toHaveKey( "/api/v2/users/{userID}/posts/{id}" );
				var path = normalizedDoc[ "paths" ][ "/api/v2/users/{userID}/posts/{id}" ];
				expect( path ).toHaveKey( "get" );
				expect( path[ "get" ] ).toHaveKey( "parameters" );

				var pageParamSearch = arrayFilter( path[ "get" ][ "parameters" ], function( parameter ) {
					return structKeyExists( parameter, "name" ) && parameter[ "name" ] == "id";
				} );

				expect( arrayLen( pageParamSearch ) ).toBe( 1 );

				expect( pageParamSearch[ 1 ].schema[ "type" ] ).toBe( "integer" );
			} );

			it( "Tests the ability to parse convention path response definition files", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				var normalizedDoc = variables.APIDoc.getNormalizedDocument();

				expect( normalizedDoc ).toHaveKey( "paths" );
				expect( normalizedDoc[ "paths" ] ).toHaveKey( "/api/v1/users" );

				var path = normalizedDoc[ "paths" ][ "/api/v1/users" ];
				expect( path ).toHaveKey( "post" );
				expect( path.post ).toHaveKey( "responses" );
				// expect( path.post.responses ).toHaveKey( "201" );
				expect( path.post.responses ).toHaveKey( "default" );

				if ( !directoryExists( variables.samplesPath ) ) {
					directoryCreate( variables.samplesPath );
				}
				if ( !directoryExists( variables.samplesPath & "/responses" ) ) {
					directoryCreate( variables.samplesPath & "/responses" );
				}


				fileWrite(
					variables.samplesPath & "/responses/handlers.api.v1.Users.add.json",
					serializeJSON( { "success" : false } )
				);
				fileWrite(
					variables.samplesPath & "/responses/handlers.api.v1.Users.add.201.json",
					serializeJSON( {
						"id"      : createUUID(),
						"success" : true
					} )
				);

				var handlerMeta = variables.model.getHandlerMetadata( {
					"handler" : "api.v1.Users",
					"module"  : "",
					"event"   : ""
				} );
				var functionMeta = variables.model.getFunctionMetadata( "add", handlerMeta );
				structDelete( functionMeta, "responses" );

				var parseArgs = {
					"type"             : "responses",
					"handlerMetadata"  : handlerMeta,
					"method"           : {},
					"functionName"     : "add",
					"methodName"       : "add",
					"functionMetadata" : functionMeta
				};

				variables.model.appendConventionSamples( argumentCollection = parseArgs );

				expect( parseArgs.method ).toHaveKey( "responses" );
				expect( parseArgs.method.responses ).toHaveKey( "default" );
				expect( parseArgs.method.responses.default ).toHaveKey( "application/json" );
				expect( parseArgs.method.responses.default[ "application/json" ] ).toHaveKey( "success" );
				expect( parseArgs.method.responses.default[ "application/json" ].success ).toBeFalse();
				expect( parseArgs.method.responses ).toHaveKey( "201" );
				expect( parseArgs.method.responses[ "201" ] ).toHaveKey( "application/json" );
				var successSample = parseArgs.method.responses[ "201" ][ "application/json" ];
				expect( successSample ).toHaveKey( "id" );
				expect( isValid( "UUID", successSample.id ) ).toBeTrue();
				expect( successSample ).toHaveKey( "success" );
				expect( successSample.success ).toBeTrue();
			} );

			it( "Tests the ability to parse convention path requestBody files", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				if ( !directoryExists( variables.samplesPath ) ) {
					directoryCreate( variables.samplesPath );
				}

				if ( !directoryExists( variables.samplesPath & "/responseBody" ) ) {
					directoryCreate( variables.samplesPath & "/responseBody" );
				}


				fileWrite(
					variables.samplesPath & "/responseBody/handlers.api.v1.Users.add.json",
					serializeJSON( {
						"firstName" : "Luis",
						"lastName"  : "Majano"
					} )
				);

				var handlerMeta = variables.model.getHandlerMetadata( {
					"handler" : "api.v1.Users",
					"module"  : "",
					"event"   : ""
				} );
				var functionMeta = variables.model.getFunctionMetadata( "add", handlerMeta );
				structDelete( functionMeta, "responseBody" );

				var parseArgs = {
					"type"             : "responseBody",
					"handlerMetadata"  : handlerMeta,
					"method"           : {},
					"functionName"     : "add",
					"methodName"       : "add",
					"functionMetadata" : functionMeta
				};

				variables.model.appendConventionSamples( argumentCollection = parseArgs );

				expect( parseArgs.method ).toHaveKey( "responseBody" );
				expect( parseArgs.method.responseBody ).toHaveKey( "firstName" );
				expect( parseArgs.method.responseBody ).toHaveKey( "lastName" );
			} );

			it( "Tests the ability to parse convention path parameter files", function() {
				expect( variables ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );

				if ( !directoryExists( variables.samplesPath ) ) {
					directoryCreate( variables.samplesPath );
				}

				if ( !directoryExists( variables.samplesPath & "/parameters" ) ) {
					directoryCreate( variables.samplesPath & "/parameters" );
				}

				var parameters = [
					{
						"name"        : "firstName",
						"in"          : "path",
						"description" : "The first name of the user",
						"required"    : true,
						"schema"      : { "type" : "string", "minimum" : 1 }
					}
				];

				fileWrite(
					variables.samplesPath & "/parameters/handlers.api.v1.Users.add.json",
					serializeJSON( parameters )
				);

				var handlerMeta = variables.model.getHandlerMetadata( {
					"handler" : "api.v1.Users",
					"module"  : "",
					"event"   : ""
				} );
				var functionMeta = variables.model.getFunctionMetadata( "add", handlerMeta );
				structDelete( functionMeta, "parameters" );

				var parseArgs = {
					"type"             : "parameters",
					"handlerMetadata"  : handlerMeta,
					"method"           : {},
					"functionName"     : "add",
					"methodName"       : "add",
					"functionMetadata" : functionMeta
				};

				variables.model.appendConventionSamples( argumentCollection = parseArgs );

				expect( parseArgs.method ).toHaveKey( "parameters" );
				expect( parseArgs.method.parameters ).toBeArray();
				expect( parseArgs.method.parameters.len() ).toBe( 1 );
				expect( parseArgs.method.parameters[ 1 ] ).toHaveKey( "name" );
				expect( parseArgs.method.parameters[ 1 ] ).toHaveKey( "in" );
				expect( parseArgs.method.parameters[ 1 ] ).toHaveKey( "description" );
				expect( parseArgs.method.parameters[ 1 ] ).toHaveKey( "required" );
			} );
		} );
	}

}
