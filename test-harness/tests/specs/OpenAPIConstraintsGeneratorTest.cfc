component
	extends   ="coldbox.system.testing.BaseTestCase"
	appMapping="/"
	accessors =true
{

	function run(){
		describe( "OpenAPI Constraints Generator", () => {
			it( "can generate constraints using parameters.json and requestBody.json", () => {
				var generator   = getInstance( "OpenAPIConstraintsGenerator@cbSwagger" );
				var constraints = generator.generateConstraintsFromOpenAPISchema(
					parametersPath  = "/includes/resources/users.add.parameters.json##user",
					requestBodyPath = "/includes/resources/users.add.requestBody.json",
					autoDiscover    = false
				);

				expect( constraints ).toBeStruct();
				expect( constraints ).toBe( {
					"country"  : { "required" : false, "type" : "string" },
					"address2" : { "required" : false, "type" : "string" },
					"zipCode"  : { "required" : true, "type" : "string" },
					"address1" : { "required" : true, "type" : "string" },
					"state"    : { "required" : true, "type" : "string" },
					"city"     : { "required" : true, "type" : "string" },
					"user"     : {
						"required"    : true,
						"constraints" : {
							"firstname" : { "required" : true, "type" : "string" },
							"lastname"  : { "required" : true, "type" : "string" },
							"email"     : { "required" : true, "type" : "string" }
						},
						"type" : "struct"
					}
				} );
			} );
		} );
	}

}
