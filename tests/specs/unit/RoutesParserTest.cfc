/*******************************************************************************
* Routes Parser Test
*******************************************************************************/
component extends="coldbox.system.testing.BaseTestCase" appMapping="/" accessors=true{
	
	this.loadColdbox=true;

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
		// do your own stuff here
	}

	function afterAll(){
		// do your own stuff here
		super.afterAll();

	}

	/*********************************** BDD SUITES ***********************************/
	
	function run(){

		describe( "Describes my test", function(){

			it("Tests something...", function(){
				expect( true ).toBeTrue();
			})
		
		});

	}

}
