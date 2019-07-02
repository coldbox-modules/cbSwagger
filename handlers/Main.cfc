/**
 * Copyright since 2016 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This handler outputs the swagger REST document
 */
component extends="coldbox.system.EventHandler"{

	// DI
	property name="routesParser" 	inject="RoutesParser@cbswagger";
	property name="settings" 		inject="coldbox:moduleSettings:cbswagger";

	/**
	 * Pre handler
	 */
	function preHandler( event, rc, prc, action, eventArguments ){
		// No layout, just in case
		event.noLayout();
		// Determine output format
		param name="rc.format" default="#variables.settings.defaultFormat#";
		// Build out document
		prc.apiDocument = routesParser.createDocFromRoutes();
	}

	/**
	 * CBSwagger Core Handler Method
	 */
	any function index( event, rc, prc ){
		// json
		if( rc.format eq "json" ){
			return json( argumentCollection=arguments );
		}
		// yaml
		return yml( argumentCollection=arguments );
	}

	/**
	 * json output
	 */
	function json( event, rc, prc ){

		event.renderData(
			type 			= "JSON",
			data 			= prc.apiDocument.getNormalizedDocument(),
			statusCode 		= "200",
			statusMessage 	= "Success"
		);

	}

	/**
	 * yml output
	 */
	function yml( event, rc, prc ){

		var fileName = getInstance( "HTMLHelper@coldbox" ).slugify( variables.settings.info.title ) & ".yml";
		event.renderData(
			contentType 	= "application/yaml",
			data 			= prc.apiDocument.asYaml(),
			statusCode 		= "200",
			statusMessage 	= "Success"
		)
		.setHTTPHeader(
			name 	= "content-disposition",
			value 	= "attachment; filename=#urlEncodedFormat( fileName )#"
		);

	}



}