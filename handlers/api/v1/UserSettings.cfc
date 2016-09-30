/**
 *
 * @name UserSettings API Controller
 * @package cbSwagger-shell
 * @description This is the User Settings API Controller
 * @author Jon Clausen <jon_clausen@silowebworks.com>
 * 
 **/
component{
	property name="UserSettingService" inject="model:UserSettingService";

	public function preHandler(event,action,eventArguments,rc,prc){
		super.preHandler(argumentCollection=arguments);
		requireRole("User");
	}

	//(GET) /api/v1/users/:id/settings
	function get(event,rc,prc){
		marshallSettings(argumentCollection=arguments);
	}

	//(PUT|PATCH) /api/v1/users/:id/settings
	function update(event,rc,prc){
		marshallSettings(argumentCollection=arguments);
		//exit if not found
		if(rc.statusCode != STATUS.SUCCESS) return;

		var UserSettings = prc.userSettings;

		var serviceResponse = UserSettingService.processSettingsUpdate(UserSettings,rc);

		if(serviceResponse.success){
			ARGUMENTS.Settings = UserSettings;
			marshallSettings(argumentCollection=arguments);
			rc.statusCode = STATUS.SUCCESS;
		} else {
			rc.data['error'] = serviceResponse.friendlyMessage;
			rc.data['validationErrors'] = serviceResponse.errors;	
			rc.statusCode = STATUS.EXPECTATION_FAILED;
		}
	}

	public function marshallSettings(event,rc,prc,UserSetting Settings){
		var currentUser=SessionService.getCurrentUser();
		//404 default
		rc.statusCode = STATUS.NOT_FOUND;
		rc.data = {};

		if(isNull(ARGUMENTS.Settings)){
			var UserSettings = Wirebox.getInstance("UserSetting").where("userId",rc.id).find();
		} else {
			var UserSettings = ARGUMENTS.Settings;
		}

		if(UserSettings.loaded() && UserSettings.getUserId() == currentUser['_id']){
			rc.data = UserSettings.getDocument();
			rc.data['href']='/api/v1/users/' &rc.id&'/settings';
			rc.statusCode = STATUS.SUCCESS;
			prc.userSettings = UserSettings;
		} else {

			if(!UserSettings.loaded()) return;

			return this.onAuthorizationFailure();
		}
	}
}