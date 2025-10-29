component{

	function configure(){
		setFullRewrites( true );

		// API Routing
		defaultAPIActions = {
			"GET":"index",
			"POST":"add",
			"PUT":"onInvalidHTTPMethod",
			"PATCH":"onInvalidHTTPMethod",
			"DELETE":"onInvalidHTTPMethod"
		};
		defaultEntityActions = {
			"GET":"get",
			"PUT":"update",
			"PATCH":"update",
			"DELETE":"delete"
		};

		/**
		* Users API (v1)
		**/

		//Login
		addRoute(
			pattern='/api/v1/users/login',
			handler='api.v1.Users',
			action={"POST":"login","DELETE":"logout"}
		);

		addRoute(
			pattern='/api/v1/users/:id/roles',
			handler='api.v1.Users',
			action={"GET":"roles"}
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

		// A secret route which is excluded in the config
		addRoute(
			pattern='/api/v1/secret',
			handler='api.v1.Users',
			action=defaultAPIActions
		);

		// Would be included in docs, but function def has @noCbSwagger attribute
		addRoute(
			pattern='/api/v1/noCbSwagger',
			handler='api.v1.Users',
			action={
				"GET": "sharedRouteDifferentHTTPMethods_get_shouldNotBeExposed",
				"POST": "sharedRouteDifferentHTTPMethods_post_shouldBeExposed"
			}
		);

		addRoute(
			pattern='/api/v1/noCbSwagger2',
			handler='api.v1.Users',
			action = {
				"GET": "loneRoute_get_shouldNotBeExposed"
			}
		);

		// @app_routes@

		// Conventions-Based Routing
		route( ":handler/:action?" ).end();
	}

}
