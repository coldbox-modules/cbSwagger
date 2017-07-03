/**
 *
 * @name User API Controller
 * @package cbSwagger-shell
 * @description This is the User API Controller
 * @author Jon Clausen <jon_clausen@silowebworks.com>
 *
 **/
component displayname="API.v1.Users"{

	this.API_BASE_URL = "/api/v1/users";

	//(GET) /api/v1/users
	function index(event,rc,prc){
		runEvent('api.v1.Users.list');
	}

	//(POST|DELETE) /api/v1/users/login
	function login(event,rc,prc){
		if(event.getHTTPMethod() is "POST"){
			var email = event.getValue("email",createUUID());
			var User = ModelUsers.where("email",email).find();
			if(User.loaded() && userService.passwordMatches(event.getValue("password",""),User.getPassword())){
				SessionService.loginUser(User);
				arguments.user = User;
				marshallUser(argumentCollection=arguments);
				rc.statusCode = STATUS.CREATED;
			} else {
				rc.data = {};
				rc.statusCode = STATUS.NOT_AUTHORIZED;
			}
		} else {
			SessionService.logoutUser();
			rc.data={};
			rc.statusCode = STATUS.NO_CONTENT;
		}
	}

	//(GET) /api/v1/users/:id
	function get(event,rc,prc){
		//404 default
		rc.statusCode = STATUS.NOT_FOUND;
		this.marshallUser(argumentCollection=arguments);
	}

	//(GET) /api/v1/users (search)
	function list(event,rc,prc){
		requireRole("User");
		this.marshallUsers(argumentCollection=arguments);
	}

	/**
	* @description Adds a new user
	* @x-parameters /includes/resources/users.add.parameters.json##user
	* @responses /includes/resources/users.add.responses.json
	* @x-SomeAdditionalInfo Here is some additional information on this path
	*/
	function add(event,rc,prc)
	{

		var creation = userService.createUser(rc);

		if(creation.success){
			rc.id = creation.result.userId;
			marshallUser(event,rc,prc,creation.result.user);
			rc.statusCode=STATUS.CREATED;

			if(event.getValue("postLogin",false)){
				SessionService.loginUser(creation.result.user);
			}

		} else {

			rc.statusCode = STATUS.NOT_ACCEPTABLE;
			rc.data['error'] = creation.friendlyMessage;
			rc.data['validationErrors'] = creation.errors;

		}

	}

	//(PUT) /api/v1/users/:id
	function update(event,rc,prc){
		requireRole("User");
		this.marshallUser(argumentCollection=arguments);
		if(structKeyExists(prc,'user') && (isUserInRole("Administrator") or prc.user.get_Id() == prc.currentUser['_id'])){
			var updated = userService.updateUser(prc.user,rc);

			if(updated.success){
				arguments.user = updated.result.user;
				rc.id = arguments.user.get_Id();
				marshallUser(argumentCollection=arguments);

			} else {

				rc.statusCode = STATUS.NOT_ACCEPTABLE;
				rc.data['error'] =updated.friendlyMessage;
				rc.data['validationErrors'] = updated.message;

			}
		} else {
			onAuthorizationFailure();
		}
	}

	//(DELETE) /api/v1/users/:id
	function delete(event,rc,prc){
		requireRole("User");
		var currentUser = getModel("User").get(prc.currentUser['_id']);
		//404 default
		rc.statusCode = STATUS.NOT_FOUND;
		this.marshallUser(argumentCollection=arguments);

		if(structKeyExists(prc,'user') && prc.user.get_Id() != currentUser.get_Id()){

			prc.user.setActive(false);
			prc.user.update();
			rc.data = {};
			rc.statusCode = STATUS.NO_CONTENT;

		} else if(structKeyExists(prc,'user')){

			rc.statusCode = STATUS.NOT_ALLOWED;
			rc.data['error'] = "You are not authorized to delete this user";
		}
	}

	//(GET) /api/v1/users/roles
	function roles(event,rc,prc){
		requireRole("User");
		var roles = getModel("UserRoles").list(asQuery=false,sortOrder='SortOrder');
		rc.statusCode = STATUS.SUCCESS;
		rc.data['roles'] = [];
		for(var role in roles){
			arrayAppend(rc.data.roles,role.asStruct());
		}
	}

	/**
	* Marshall Single User Data
	**/
	private function marshallUser( event, rc, prc, User user ){
		//404 default
		rc.statusCode = STATUS.NOT_FOUND;

		if(!isNull( arguments.user ) ){
			var thisUser = arguments.user;
		} else {
			var thisUser = ModelUsers.load(rc.id);
		}

		if( thisUser.loaded() && thisUser.getActive() ){
			rc.data 	= this.defaultUserResponse( thisUser );
			prc.user 	= thisUser;
			rc.statusCode = STATUS.SUCCESS;
		}
	}

	/**
	* Marshall Multiple Users Data
	**/
	private function marshallUsers( event, rc, prc ){
		rc.data[ "users" ] = [];

		var serviceResponse = userService.searchUsers( rc );

		var users = serviceResponse.result.users;
		//list methods return public data only
		var cursor = users.asCursor();

		while(cursor.hasNext()){
			var User = cursor.next();
			var userId = len(User['idTag'])?User['idTag']:User['_id'];
			sUser = {
				"firstname":user['firstName'],
				"lastname":user['lastName'],
				"href":this.API_BASE_URL&'/'&userId,
				"images":CDEService.commonImageHrefs(User['_id'])
			};
			sUser['href'] = this.API_BASE_URL&'/'&userId;
			arrayAppend(rc.data.users,sUser);
		}

		cursor.close();

		rc.statusCode = STATUS.SUCCESS;

	}

	/**
	* Assemble the default user response
	**/
	private struct function defaultUserResponse( required User user ){
		var sUser 		= userService.permissableData( arguments.user );
		var userId 		= len( arguments.user.getIdTag() ) ? arguments.user.getIdTag() : arguments.user.get_id();
		sUser[ 'href' ] 	= this.API_BASE_URL & '/' & userId;
		//assemble default image sizes
		sUser[ 'images' ] = CDEService.commonImageHrefs( arguments.user.get_id() );
		return sUser;
	}


}
