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
	function index( event, rc, prc ){
	}

	//(POST|DELETE) /api/v1/users/login
	function login( event, rc, prc ){
	}

	//(GET) /api/v1/users/:id
	function get( event, rc, prc ){
	}

	/**
	* @hint Adds a new user
	* @parameters /includes/resources/users.add.parameters.json##user
	* @responses /includes/resources/users.add.responses.json
	* @x-SomeAdditionalInfo Here is some additional information on this path
	*/
	function add( event, rc, prc ){
	}


	/**
	* @param-firstname { "type": "string", "required" : "false", "in" : "query" }
	* @param-lastname { "type": "string", "required" : "false", "in" : "query" }
	* @param-email { "type": "string", "required" : "false", "in" : "query" }
	* @response-default { "description" : "User successfully updated", "schema" : "/includes/resources/schema.json##user" }
	**/
	function update( event, rc, prc ) description="Updates a user"{
	}

	//(DELETE) /api/v1/users/:id
	function delete( event, rc, prc ){
	}

	//(GET) /api/v1/users/roles
	function roles( event, rc, prc ){
	}

}
