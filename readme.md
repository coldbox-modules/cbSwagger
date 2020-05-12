[![Build Status](https://travis-ci.org/coldbox-modules/cbSwagger.svg?branch=development)](https://travis-ci.org/coldbox-modules/cbSwagger)

# Welcome to the ColdBox Swagger Module

This module automatically generates OpenAPI ( fka Swagger ) documenation from your configured application and module routes.  This module utilizes the [v3.0.2 OpenAPI Specification]([https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md])

## License

Apache License, Version 2.0.

## Important links

- https://github.com/coldbox-modules/cbSwagger

## Resources

- https://swagger.io/specification
- https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md
- https://idratherbewriting.com/learnapidoc/pubapis_openapi_tutorial_overview
- https://blog.readme.io/an-example-filled-guide-to-swagger-3-2/

## System Requirements

- Lucee 5+
- Adobe ColdFusion 2016+

## Pre-requisites

To operate, the module requires that SES routing be enabled in your application.  For more information [read the official documentation](https://coldbox.ortusbooks.com/the-basics/routing).

## Install cbSWagger ( via Commandbox )

`box install cbSwagger`

> Note:  Omit the `box` from your command, if you are already in the Commandbox interactive shell

## Configure cbSwagger to auto-detect your API Routes

By default, cbSwagger looks for routes beginning with `/api/*` prefix.  By adding a `cbSwagger` configuration key to your Coldbox configuration, you can add additional metadata to the OpenAPI JSON produced by the module entry point and configure this module for operation.

* `routes:array` :  An array of route prefixes to search for and add to the resulting documentation.
* `defaultFormat:string` : The default output format of the documentation. Valid options are `json` and `yml`.

A full configuration example is provided below:

```js
cbswagger = {
	// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
	"routes" : [ "api" ],
	// The default output format: json or yml
	// Any routes to exclude
	"excludeRoutes"	: [],
	"defaultFormat" : "json",
	// A convention route, relative to your app root, where request/response samples are stored ( e.g. resources/apidocs/responses/[module].[handler].[action].[HTTP Status Code].json )
	"samplesPath" : "resources/apidocs",
	// Information about your API
	"info"		:{
		// A title for your API
		"title" 			: "My Awesome API",
		// A description of your API
		"description" 		: "This API produces amazing results and data.",
		// A terms of service URL for your API
		"termsOfService"	: "",
		//The contact email address
		"contact" 		:{
			"name": "API Support",
			"url": "http://www.swagger.io/support",
			"email": "info@ortussolutions.com"
		},
		//A url to the License of your API
		"license": {
			"name": "Apache 2.0",
			"url": "http://www.apache.org/licenses/LICENSE-2.0.html"
		},
		//The version of your API
		"version":"1.0.0"
	},

	// Tags
	"tags" : [
		{
			"name": "pet",
			"description": "Pets operations"
		}
	],

	// https://swagger.io/specification/#externalDocumentationObject
	"externalDocs" : {
		"description": "Find more info here",
		"url": "https://blog.readme.io/an-example-filled-guide-to-swagger-3-2/"
	},

	// https://swagger.io/specification/#serverObject
	"servers" : [
		{
			"url" 			: "https://mysite.com/v1",
			"description" 	: "The main production server"
		},
		{
			"url" 			: "http://127.0.0.1:60299",
			"description" 	: "The dev server"
		}
	],

	// An element to hold various schemas for the specification.
	// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#componentsObject
	"components" : {

		// Define your security schemes here
		// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securitySchemeObject
		"securitySchemes" : {
			"UserSecurity" : {
				// REQUIRED. The type of the security scheme. Valid values are "apiKey", "http", "oauth2", "openIdConnect".
				"type" 			: "http",
				// A short description for security scheme. CommonMark syntax MAY be used for rich text representation.
				"description" 	: "HTTP Basic auth",
				// REQUIRED. The name of the HTTP Authorization scheme to be used in the Authorization header as defined in RFC7235.
				"scheme" 		: "basic"
			},
			"APIKey" : {
				"type" 			: "apiKey",
				"description" 	: "An API key for security",
				"name" 			: "x-api-key",
				"in" 			: "header"
			}
		}
	},

	// A default declaration of Security Requirement Objects to be used across the API.
	// https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#securityRequirementObject
	// Only one of these requirements needs to be satisfied to authorize a request.
	// Individual operations may set their own requirements with `@security`
	"security" : [
		{ "APIKey" : [] },
		{ "UserSecurity" : [] }
	]
};

```

## Outputting Documentation (json|yml)

You can visit the API documentation by hitting the `/cbSwagger` route.  This will trigger the default format (json) to be sent to the output.

### Format Parameter

You can force the format by using the `?format={format}` in the URI.  The valid options are `json` and `yml`

```
http://localhost/cbSwagger?format=yml
http://localhost/cbSwagger?format=json
http://localhost/cbSwagger/json
http://localhost/cbSwagger/yml
```

## Handler Introspection & Documentation attributes

`cbSwagger` will automatically introspect your API handlers provided by your routing configuration.  You may provide additional function attributes, which will be picked up and included in your documentation.  The content body of these attributes may be provided as JSON, plain text, or may provided a file pointer which will be included as a `$ref` attribute.  Some notes on function attributes:

- Metadata attributes using a `response-` prefix in the annotation will be parsed as responses.   For example `@response-200 { "description" : "User successfully updated", "schema" : "/resources/apidocs/schema.json##user" }` would populate the `200` responses node for the given method ( in this case, `PUT /api/v1/users/:id` ). If the annotation text is not valid JSON or a file pointer, this will be provided as the response description.
- Metadata attributes prefixed with `param-` will be included as paramters to the method/action.  Example: `@param-firstname { "type": "string", "required" : "false", "in" : "query" }` If the annotation text is not valid JSON or a file pointer, this will be provided as the parameter description and the parameter requirement will be set to `false`.
- Parameters provided via the route ( e.g. the `id` in `/api/v1/users/:id` ) will always be included in the array of parameters as required for the method.  Annotations on those parameters may be used to provide additional documentation.
- [Security Requirement Objects](https://swagger.io/specification/#securityRequirementObject) defined in the cbSwagger config will be displayed on every API method, except methods that override the default with `@security`. You may use the name of a security scheme, a JSON array of Security Requirement Objects, or a file pointer. Security Requirement Objects must have the same name as a Security Scheme Object defined under components in `cbSwagger` settings.
- You may also provide paths to JSON files which describe complex objects which may not be expressed within the attributes themselves.  This is ideal to provide an endpoint for [parameters](https://swagger.io/specification/#parameterObject) and [responses](https://swagger.io/specification/#responsesObject)  If the atttribute ends with `.json`, this will be included in the generated OpenAPI document as a [$ref include](https://swagger.io/specification/#pathItemObject).
- Attributes which are not part of the swagger path specification should be prefixed with an `x-`, [x-attributes](https://swagger.io/specification/#specificationExtensions) are an official part of the OpenAPI Specification and may be used to provide additional information for your developers and consumers
- `hint` attributes, provided as either comment `@` annotations or as function body attributes will be treaded as the description for the method
- `description` due to variances in parsing comment annotations, `description` annotations must be provided as attributes of the function body.  For example, you would use `function update( event, rc, prc ) description="Updates a user"{}` rather than `@description Updates a user`

*Basic Example:*

```js
//(POST) /api/v1/users
function add( event, rc, prc )
	description="Adds a new user"
	parameters="~users.add.parameters.json"
	responses="~users.add.responses.json"
	security="APIKey"
	x-SomeAdditionalInfo="Here is some additional information on this path"
{

	...[ Your code here ]...

}
```

*Example using file pointers:*

```js
/**
* @hint Adds a new user
* @x-parameters ~users.add.parameters.json##user
* @responses ~users.add.responses.json
* @x-SomeAdditionalInfo Here is some additional information on this path
*/
function add( event, rc, prc ){

	...[ Your code here ]...

}

```

*Example using JSON ( + file pointers )*

_Note: Because CFML has its own `parameters` key within the function metadata, we would pull in a document of parameters using `x-parameters`, which will appear as `parameters` in the swagger method definition_

```js
/**
 * @hint Adds a new user
 * @x-parameters ~users.add.parameters.json
 * @responses ~users.add.responses.json
 * @x-SomeAdditionalInfo Here is some additional information on this path
 * @security ~users.add.security.json
 * @requestBody {
 * 	"description" : "User to add",
 * 	"required" : true,
 * 	"content" : {
 * 		"application/json" : {
 * 			"schema" : { "$ref" : "/includes/apidocs/NewUser.json" }
 * 		}
 * 	}
 * }
 */
function add( event, rc, prc ){
}


/**
 * @param-firstname { "schema" : { "type": "string" }, "required" : "false", "in" : "query" }
 * @param-lastname { "schema" : { "type": "string" }, "required" : "false", "in" : "query" }
 * @param-email { "schema" : { "type": "string" }, "required" : "false", "in" : "query" }
 * @security [ { "APIKey": [] } ]
 * @response-default { "description" : "User successfully updated", "content" : { "application/json" : { "schema" : { "$ref" : "/resources/apidocs/schema.json##user" } } } }
 */
function update( event, rc, prc ) description="Updates a user"{
}
```

### `~` expand path

The shortcut notation to expand the path to the `samplesPath` setting is by using the `~` prefix.  However, please note that this prefix only works on the annotations within a component NOT within a json document.

*Using convention paths to generate documentation schema and samples*

Conventions also exist, which will allow you to place JSON files within a conventions directory, defined by the `samplesPath` setting, which will automatically be included as part of your documentation. The default samples path is `resources/apidocs`.  A JSON file placed, for example, at the location of `resources/apidocs/responses/api.v1.Users.add.201.json`, would automatically be picked as the `201` status code response for the `add` method of the `Users` handler, within the `api.v1` directory.

In addition to the `responses` sub-directory, the directories of `parameters` and `responseBody` will also be inspected for content which matches the route/event being parsed. The latter two directories are parsed as-is, and are assumed to be in a valid Swagger specification format.

File naming conventions supported include:

* `[handler].[methodName].json` - all sample types
* `[moduleName].[handler].[methodName].json` - all sample types
* `[handler].[methodName](.[status code]).json` - responses with or without status codes
* `[moduleName].[handler].[methodName](.[status code]).json` - responses with or without status codes

### Operation Ids

You can influence the operation Ids by adding a `displayName` to your handler CFC.

```
component displayName="API.v1.Users"{

}
```

********************************************************************************
Copyright Since 2016 Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************

### HONOR GOES TO GOD ABOVE ALL

Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the
Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD

 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
