component extends="coldbox.system.testing.BaseTestCase" appMapping="/" {

	function run(){
		describe( "cbSwagger document rendering", function(){
			beforeEach( function(){
				setup();
				getController()
					.getCacheBox()
					.getCache( "template" )
					.clearAll();
			} );

			it( "renders a cached JSON document as an object", function(){
				var firstRequest  = execute( route = "/cbswagger", renderResults = true );
				var firstDocument = deserializeJSON( firstRequest.getValue( "cbox_rendered_content" ) );

				expect( firstDocument ).toBeStruct();
				expect( firstDocument ).toHaveKey( "openapi" );

				var cachedRequest  = execute( route = "/cbswagger", renderResults = true );
				var cachedDocument = deserializeJSON( cachedRequest.getValue( "cbox_rendered_content" ) );

				expect( cachedDocument ).toBeStruct();
				expect( cachedDocument ).toHaveKey( "openapi" );
			} );
		} );
	}

}
