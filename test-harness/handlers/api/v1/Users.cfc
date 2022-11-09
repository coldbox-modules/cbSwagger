/**
 *
 * @name User API Controller
 * @package cbSwagger-shell
 * @description This is the User API Controller
 * @author Jon Clausen <jon_clausen@silowebworks.com>
 *
 **/
component displayname="API.v1.Users" {

	this.API_BASE_URL = "/api/v1/users";

	/**
	 * (GET) /api/v1/users
	 *
	 * @event
	 * @rc
	 * @prc
	 */
	function index( event, rc, prc ) {
	}

	// (POST|DELETE) /api/v1/users/login
	function login( event, rc, prc ) {
	}

	// (GET) /api/v1/users/:id
	function get( event, rc, prc ) {
	}

	// (POST) /api/v1/users
	/**
	 * @hint Adds a new user
	 * @tags Simple,List
	 * @parameters ~users.add.parameters.json##user
	 * @response-201 ~users.add.responses.json##201
	 * @response-500 /includes/resources/users.add.responses.json##500
	 * @x-SomeAdditionalInfo Here is some additional information on this path
	 * @requestBody {
	 * 	"description" : "User to add",
	 * 	"required" : true,
	 * 	"content" : {
	 * 		"application/json" : {
	 * 			"schema" : { "$ref" : "~NewUser.json" }
	 * 		}
	 * 	}
	 * }
	 */
	function add( event, rc, prc ) {
	}


	/**
	 * @tags [ "json", "list" ]
	 * @param-firstname { "schema" : { "type": "string" }, "required" : "false", "in" : "query" }
	 * @param-lastname { "schema" : { "type": "string" }, "required" : "false", "in" : "query" }
	 * @param-email { "schema" : { "type": "string" }, "required" : "false", "in" : "query" }
	 * @response-default { "description" : "User successfully updated", "content" : { "application/json" : { "schema" : { "$ref" : "/includes/resources/schema.json##user" } } } }
	 */
	function update( event, rc, prc ) description="Updates a user" {
	}

	// (DELETE) /api/v1/users/:id
	function delete( event, rc, prc ) {
	}

	/**
	 * @route /api/v1/users/:id/roles
	 * @summary Retrieves the roles for a user.
	 * @hint A longer description here for retrieving the roles for a user.
	 */
	function roles( event, rc, prc ) {
	}

}
