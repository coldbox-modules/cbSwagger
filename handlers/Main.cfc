/**
 * Copyright since 2016 by Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This handler outputs the swagger REST document
 */
component extends="coldbox.system.EventHandler"{

	// DI
	property name="routesParser" inject="RoutesParser@cbswagger";

	/**
	 * Pre handler
	 */
	function preHandler( event, rc, prc, action, eventArguments ){
		event.noLayout();
	}

	/**
	 * CBSwagger Core Handler Method
	 */
	any function index( event, rc, prc ){
		var APIDoc = routesParser.createDocFromRoutes();
		event.renderData(
			type 			= "JSON",
			data 			= APIDoc.getNormalizedDocument(),
			statusCode 		= "200",
			statusMessage 	= "Success"
		);
	}

}