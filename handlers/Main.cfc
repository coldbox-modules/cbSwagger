/**
 * Copyright since 2016 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This handler outputs the swagger REST document
 */
component extends="coldbox.system.EventHandler" {

	// DI
	property name="routesParser" inject="RoutesParser@cbswagger";
	property name="settings"     inject="coldbox:moduleSettings:cbswagger";
	property name="environment"     inject="coldbox:setting:environment";
	property name="templateCache"   inject="cachebox:template";

	function preHandler(
		event,
		rc,
		prc,
		action,
		eventArguments
	){
		if ( structKeyExists( rc, "requestTimeout" ) && isNumeric( rc.requestTimeout ) ) {
			setting requestTimeout=rc.requestTimeout;
		}

		// No layout, just in case
		event.noLayout();
		// Determine output format
		param name     ="rc.format" default="#variables.settings.defaultFormat#";
		var cacheKey = "cbswagger_parsed_api_document";
		// Build out document
		if( ( rc.keyExists( "swaggerCache" ) && !rc.swaggerCache ) ){
			templateCache.clear( cacheKey );
		}
		prc.apiDocument= settings.cacheEnabled ? templateCache.getOrSet( cacheKey, () => routesParser.createDocFromRoutes(), 60 * 12 ) : routesParser.createDocFromRoutes();

		// Shared CORS headers
		event.setHTTPHeader(
			name  = "Access-Control-Allow-Origin",
			value = event.getHTTPHeader( "Origin", "*" )
		);
		event.setHTTPHeader(
			name  = "Access-Control-Allow-Credentials",
			value = true
		);
	}

	function options( event, rc, prc ){
		event.setHTTPHeader(
			name  = "Access-Control-Allow-Headers",
			value = event.getHTTPHeader( "Access-Control-Request-Headers", "" )
		);
		event.setHTTPHeader(
			name  = "Access-Control-Allow-Methods",
			value = event.getHTTPHeader(
				"Access-Control-Request-Method",
				event.getHTTPMethod()
			)
		);
		event.setHTTPHeader(
			name  = "Access-Control-Max-Age",
			value = 60 * 60 * 24 // 1 day
		);
		event.renderData( "plain", "Preflight OK" );
	}

	/**
	 * CBSwagger Core Handler Method
	 */
	function index( event, rc, prc ){
		var cacheKey = "cbswagger_parsed_api_document";
		if( rc.keyExists( "swaggerCache" ) && !rc.swaggerCache ){
			templateCache.clear( cacheKey );
		}
		// json
		if ( rc.format eq "json" ) {
			return json( argumentCollection = arguments );
		}
		// yaml
		return yml( argumentCollection = arguments );

	}

	/**
	 * json output
	 */
	function json( event, rc, prc ){
		var cacheKey = "cbswagger_parsed_json_document";
		if( rc.keyExists( "swaggerCache" ) && !rc.swaggerCache ){
			templateCache.clear( cacheKey );
		}
		event.renderData(
			type          = "JSON",
			data          = settings.cacheEnabled ? templateCache.getOrSet( cacheKey, () => prc.apiDocument.getNormalizedDocument(), 60 * 12 ) : prc.apiDocument.getNormalizedDocument(),
			statusCode    = "200",
			statusMessage = "Success"
		);
	}

	/**
	 * yml output
	 */
	function yml( event, rc, prc ){
		var fileName = getInstance( "HTMLHelper@coldbox" ).slugify( variables.settings.info.title ) & ".yml";
		var cacheKey = "cbswagger_parsed_yml_document";
		if( rc.keyExists( "swaggerCache" ) && !rc.swaggerCache ){
			templateCache.clear( cacheKey );
		}
		event
			.renderData(
				contentType   = "application/yaml",
				data          = settings.cacheEnabled ? templateCache.getOrSet( cacheKey, () => prc.apiDocument.asYaml(), 60 * 12 ) : prc.apiDocument.asYaml(),
				statusCode    = "200",
				statusMessage = "Success"
			)
			.setHTTPHeader(
				name  = "content-disposition",
				value = "attachment; filename=#urlEncodedFormat( fileName )#"
			);
	}

}
