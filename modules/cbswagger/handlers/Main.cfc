/**
* My Event Handler Hint
*/
component extends="coldbox.system.EventHandler"{

	function preHandler( event, rc, prc, action, eventArguments){
		event.noLayout();
	}


	/**
	* CBSwagger Core Handler Method
	*/
	any function index( event, rc, prc ){
		var APIDoc = getWirebox().getInstance( "RoutesParser@cbswagger" ).createDocFromRoutes();
		event.renderData( type="JSON", data=APIDoc.getNormalizedDocument(), statusCode="200", statusMessage="Success");  
	}
	
}