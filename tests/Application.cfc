/**
* Copyright Since 2005 Ortus Solutions, Corp
* www.coldbox.org | www.luismajano.com | www.ortussolutions.com | www.gocontentbox.org
**************************************************************************************
*/
component{
	this.name = "A TestBox Runner Suite " & hash( getCurrentTemplatePath() );
	// any other application.cfc stuff goes below:
	this.sessionManagement = true;

	// COLDBOX STATIC PROPERTY, DO NOT CHANGE UNLESS THIS IS NOT THE ROOT OF YOUR COLDBOX APP
	COLDBOX_APP_ROOT_PATH = getDirectoryFromPath( expandPath( '../Application.cfc' ) );

	// The web server mapping to this application. Used for remote purposes or static purposes
	COLDBOX_APP_MAPPING   = "/";
	// COLDBOX PROPERTIES
	COLDBOX_CONFIG_FILE   = "config.Coldbox";
	// COLDBOX APPLICATION KEY OVERRIDE
	COLDBOX_APP_KEY 		 = "";

	// any mappings go here, we create one that points to the root called test.
	this.mappings[ "/tests" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );
	this.mappings[ "/root" ]   = rootPath;
	this.mappings[ "/SwaggerSDK" ] = COLDBOX_APP_ROOT_PATH & "modules/swagger-sdk";
	this.mappings[ "/cbswagger" ] = COLDBOX_APP_ROOT_PATH & "modules/cbswagger";
	this.mappings[ "/cbjavaloader" ] = COLDBOX_APP_ROOT_PATH & "modules/cbjavaloader";
	
	// application start
	public boolean function onApplicationStart(){
		application.cbBootstrap = new coldbox.system.Bootstrap( COLDBOX_CONFIG_FILE, COLDBOX_APP_ROOT_PATH, COLDBOX_APP_KEY, COLDBOX_APP_MAPPING );
		application.cbBootstrap.loadColdbox();
		return true;
	}

	// request start
	public boolean function onRequestStart( String targetPage ){
		// Clear out the previous framework objects so that the first spec with `loadColdbox` set to `true` will reload them
		if( structKeyExists( url, "persistColdbox" ) && !url.persistColdbox ){

			structDelete( application, "cbController" );
			structDelete( application, "wirebox" );	
		
		}
		return true;
	}

}