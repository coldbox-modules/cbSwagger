##Prerequisites

To operate, the module requires that SES routing be enabled in your application.  For more information [read the official documentation](https://coldbox.ortusbooks.com/content/Routing/routes_configuration.html).

##Install cbSWagger ( via Commandbox )

`box install cbswagger`

Note:  Omit the `box` from your command, if you are already in the Commandbox interactive shell

##

##Configure cbSwagger to auto-detect your API Routes

By default, cbSwagger looks for routes beginning with `api`.  By adding a `cbSwagger` configuration key to your Coldbox configuration, you can add additional metadata to the OpenAPI JSON produced by the module entry point.  A full configuration example is provided below:

```
cbswagger = {
	// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
	"routes":["api"],
	//A base path prefix for your API - leave blank if all routes are configured to the root of the site
	"basePath":"",
	//The API host
	"host":"",
	// Information about your API
	"info":{
		//The contact email address
		"contact":"",
		//A title for your API
		"title":"",
		//A descritpion of your API
		"description":"",
		//A url to the License of your API
		"license":"",
		//A terms of service URL for your API
		"termsOfService":"",
		//The version of your API
		"version":""
	},
	//An array of all of the request body formats your your API is configured to consume 
	"consumes": ["application/json","multipart/form-data","application/x-www-form-urlencoded"],
	//An array of all of the response body formats your API delivers
	"produces": ["application/json"]
};

```

##Handler Introspection & Documentation attributes

cbSwagger will automatically introspect your API handlers provided by your routing configuration.  You may provide additional function attributes, which will be picked up and included in your documentation.  Some notes on function attributes:

* Attributes which are not part of the swagger path specification should be prefixed with an `x-`, [x-attributes](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#specificationExtensions) are an official part of the OpenAPI Specification and may be used to provide additional information for your developers and consumers
* You may also provide paths to JSON files which describe complex objects which may not be expressed within the attributes themselves.  This is ideal to provide an endpoint for [parameters](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#parameterObject) and [responses](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#responseObject)  If the atttribute ends with `.json`, this will be included in the generated OpenAPI document as a [$ref include](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#pathItemObject).

Example:


```
//(POST) /api/v1/users
function add(event,rc,prc)
	description="Adds a new user"
	parameters="/includes/resources/users.add.parameters.json"
	responses="/includes/resources/users.add.responses.json"
	x-SomeAdditionalInfo="Here is some additional information on this path"
{

	...[ Your code here ]...
		
}
```
