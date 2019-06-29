/**
 * Copyright since 2016 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This handler outputs the swagger REST document
 */
component extends="coldbox.system.EventHandler"{

	// DI
	property name="routesParser" 			inject="RoutesParser@cbswagger";
	property name="cbSwaggerSettings" 		inject="coldbox:moduleSettings:cbswagger";

	/**
	 * Pre handler
	 */
	function preHandler( event, rc, prc, action, eventArguments ){
		event.noLayout();
		// Determine output format
		param name="rc.format" default="#variables.cbSwaggerSettings.defaultFormat#";
	}

	/**
	 * CBSwagger Core Handler Method
	 */
	any function index( event, rc, prc ){
		var apiDocument = routesParser.createDocFromRoutes();

		// json
		if( rc.format eq "json" ){
			event.renderData(
				type 			= "JSON",
				data 			= apiDocument.getNormalizedDocument(),
				statusCode 		= "200",
				statusMessage 	= "Success"
			);
		}
		// yaml
		else {
			var fileName = getInstance( "HTMLHelper@coldbox" ).slugify( variables.cbSwaggerSettings.info.title ) & ".yml";
			event.renderData(
				contentType 	= "application/yaml",
				data 			= apiDocument.asYaml(),
				statusCode 		= "200",
				statusMessage 	= "Success"
			)
			.setHTTPHeader(
				name 	= "content-disposition",
				value 	= "attachment; filename=#urlEncodedFormat( fileName )#"
			);
		}

	}

}