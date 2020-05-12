component {

	// Module Properties
	this.title              = "v3";
	this.author             = "";
	this.webURL             = "";
	this.description        = "";
	this.version            = "1.0.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup   = true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint         = "v3";
	// Inherit Entry Point
	this.inheritEntryPoint  = true;
	// Model Namespace
	this.modelNamespace     = "v3";
	// CF Mapping
	this.cfmapping          = "v3";
	// Auto-map models
	this.autoMapModels      = true;
	// Module Dependencies
	this.dependencies       = [];

	function configure() {
		// parent settings
		parentSettings = {};

		// module settings - stored in modules.name.settings
		settings = {};

		// Layout Settings
		layoutSettings = { defaultLayout : "" };

		// SES Routes
		router.route( "/" ).to( "Home.index" );

		// SES Resources
		resources = [];

		// Custom Declared Points
		interceptorSettings = { customInterceptionPoints : "" };

		// Custom Declared Interceptors
		interceptors = [];

		// Binder Mappings
		// binder.map("Alias").to("#moduleMapping#.models.MyService");
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad() {
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload() {
	}

}
