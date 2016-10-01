 /**
 *
 * @name User API Controller
 * @package cbSwagger-shell
 * @description This is the User Posts API Controller
 * @author Jon Clausen <jon_clausen@silowebworks.com>
 * 
 **/
component name="API.v1.Posts"{
	property name="PostService" inject="CDEPostService";

	function preHandler(event,action,eventArguments,rc,prc){
		super.preHandler(argumentCollection=arguments);
		requireRole("User");
	}

	function index(event,rc,prc){
		return this.list(argumentCollection=arguments);
	}

	//(GET) /api/v1/users/:id/posts
	function list(event,rc,prc){
		marshallPosts(argumentCollection=arguments);
	}

	//(POST) /api/v1/users/:id/posts
	function add(event,rc,prc){
		var rc.userId = prc.currentUser['_id'];
		var ServiceResponse = getModel("CDEPostService").createPost(ARGUMENTS.rc);
		if(ServiceResponse.success){
			ARGUMENTS.Post = ServiceResponse.result.post;
			marshallPost(argumentCollection=ARGUMENTS);
			ARGUMENTS.rc.statusCode = STATUS.CREATED;
		} else {
			rc.data = {
				"error":ServiceResponse.friendlyMessage,
				"errors":ServiceResponse.errors
			}
			rc.statusCode = STATUS.EXPECTATION_FAILED;
		}
	}

	//(GET) /api/v1/users/:id/posts/:PostId
	function get(event,rc,prc){
		marshallPost(argumentCollection=arguments);
	}

	//(GET) /api/v1/users/:id/posts/:PostId
	function update(event,rc,prc){
		marshallPost(argumentCollection=arguments);
		//exit out if an error
		if(ARGUMENTS.rc.statusCode != STATUS.success) return;
		
		//return authorization error if not owner
		if(ARGUMENTS.prc.currentUser['_id'] != ARGUMENTS.rc.id){
			ARGUMENTS.rc.data = {"error":"You are not authorized to modify this post."}
			ARGUMENTS.rc.statusCode = STATUS.NOT_AUTHORIZED;
			return;
		}

		//Updates begin once all of our checks have been performed
		var ServiceResponse = PostService.updatePost(prc.Post,ARGUMENTS.rc);
		if(ServiceResponse.success){
			ARGUMENTS.Post = ServiceResponse.result.Post;
			marshallPost(argumentCollection=arguments);
		} else {
			ARGUMENTS.rc.data = {
				"error":ServiceResponse.friendlyMessage,
				"errors":ServiceResponse.errors
			}
			ARGUMENTS.rc.statusCode = STATUS.EXPECTATION_FAILED;
		}		

	}

	//(DELETE) /api/v1/users/:id/posts/:PostId
	function delete(event,rc,prc){
		marshallPost(argumentCollection=arguments);
		//exit out if an error
		if(rc.statusCode != STATUS.success) return;
		//return authorization error if not owner
		if(prc.currentUser['_id'] != rc.id){
			rc.data = {"error":"You are not authorized to delete this user Post."}
			rc.statusCode = STATUS.NOT_AUTHORIZED;
			return;
		}
		
		//proceed with deletion if our checks have passed
		var ServiceResponse = PostService.deletePost(prc.Post);
		if(ServiceResponse.success){
			rc.statusCode = STATUS.NO_CONTENT;
			rc.data = {};
		} else {
			rc.data = {
				"error":ServiceResponse.friendlyMessage,
				"errors":ServiceResponse.errors
			}	
			rc.statusCode = STATUS.EXPECTATION_FAILED;		
		}

	}


	/**
	* The default response for an Entity
	**/
	private function defaultPostResponse(required Post){
		var response = Membership.getDocument();
		response['href']='/api/v1/posts/' & rc.id;
		return response;
	}


	/**
	* Marshall a Response for a Post
	**/
	private function marshallPost(event,rc,prc,CDEPost Post){
		//404 default
		rc.statusCode = STATUS.NOT_FOUND;
		var CurrentUser = prc.CurrentUser;
		
		if(!isNull(ARGUMENTS.Post)){
			var Post = ARGUMENTS.Post;
		} else {
			var Post = getModel("CDEPost").load(rc.PostId);	
		}

		if(
			Post.loaded() 
			&& 
			PostService.isVisibleToUser(Post,CurrentUser)
		)
		{
			rc.data = Post.getDocument();
			//append our api urls
			rc.data['href']='/api/v1/users/' & Post.getUser_Id() & '/posts/' & Post.get_id();
			rc.data['user']='/api/v1/users/' & Post.getUser_Id();
			prc.Post = Post;
			rc.statusCode = STATUS.SUCCESS;
		} else if(Post.loaded()){
			rc.data = {"error":"The current user is not authorized to view this Post information"};
			rc.statusCode = STATUS.NOT_AUTHORIZED;
		}
	}

	/**
	* Marshal an array of posts
	**/
	private function marshallPosts(event,rc,prc){
		//404 default
		rc.statusCode = STATUS.NOT_FOUND;
		rc.data = {
			"posts":[]
		}
		
		var PostSearch = getModel("CDEPostService").search(rc);
		var Posts = PostSearch.result.posts.asCursor();
		
		while(Posts.hasNext()){
			var entityDoc = Wirebox.getInstance("MongoUtil@cbmongodb").toCF(Posts.next());
			entityDoc['href']='/api/v1/users/' & rc.id & '/posts/' & entityDoc['_id'];
			entityDoc['user']='/api/v1/users/' & rc.id;
			entityDoc['members']='/api/v1/users/' & rc.id & '/posts/' & entityDoc['_id'] & '/members';
			arrayAppend(rc.data.posts,entityDoc);
		}
		//close cursor
		Posts.close();
		rc.statusCode=STATUS.SUCCESS;
	}
}