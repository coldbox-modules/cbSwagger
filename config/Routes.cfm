<cfscript>
	// Allow unique URL or combination (false)
	setUniqueURLS(false);
	// Auto reload configuration, true in dev makes sense
	//setAutoReload(false);
	// Sets automatic route extension detection and places the extension in the rc.format
	// setExtensionDetection(true)
	// setValidExtensions('xml,json,jsont,rss,html,htm');
	
	// Base URL
	if( len(getSetting('AppMapping') ) lte 1){
		setBaseURL("http://#cgi.HTTP_HOST#/index.cfm");
	}
	else{
		setBaseURL("http://#cgi.HTTP_HOST#/#getSetting('AppMapping')#/index.cfm");
	}

	
	// API Routing
	var defaultAPIActions = {
		"GET":"index",
		"POST":"add",
		"PUT":"onInvalidHTTPMethod",
		"PATCH":"onInvalidHTTPMethod",
		"DELETE":"onInvalidHTTPMethod"
	};
	var defaultEntityActions = {
		"GET":"get",
		"PUT":"update",
		"PATCH":"update",
		"DELETE":"delete"
	};

	
	/**
	* Users API (v1)
	**/


	//User Posts

	addRoute(
		pattern='/api/v1/users/:id/posts/:PostId',
		handler='api.v1.UserPosts',
		action=defaultEntityActions
	);

	addRoute(
		pattern='/api/v1/users/:id/posts',
		handler='api.v1.UserPosts',
		action=defaultAPIActions
	);

	addRoute(
		pattern='/api/v1/users/:id/media/:mediaId',
		handler='api.v1.UserMedia',
		action=defaultEntityActions
	);

	addRoute(
		pattern='/api/v1/users/:id/media',
		handler='api.v1.UserMedia',
		action=defaultAPIActions
	);


	/**
	* Core Users API - api.v1.Users
	**/

	//User Settings
	addRoute(
		pattern='/api/v1/users/:id/settings',
		handler='api.v1.UserSettings',
		action={"GET":"get","PUT":"update","PATCH":"update","POST":"onInvalidHTTPMethod","DELETE":"onInvalidHTTPMethod"}
	);

	//Login
	addRoute(
		pattern='/api/v1/users/login',
		handler='api.v1.Users',
		action={"POST":"login","DELETE":"login"}
	);

	addRoute(
		pattern='/api/v1/users/:id',
		handler='api.v1.Users',
		action=defaultEntityActions
	);

	addRoute(
		pattern='/api/v1/users',
		handler='api.v1.Users',
		action=defaultAPIActions
	);
	
	
	// Your Application Routes
	addRoute(pattern=":handler/:action?");
</cfscript>