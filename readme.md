[![Build Status](https://travis-ci.org/coldbox-modules/cbSwagger.svg?branch=development)](https://travis-ci.org/coldbox-modules/cbSwagger)

# Welcome to the ColdBox Swagger Module
This module automatically generates OpenAPI ( fka Swagger ) documenation from your configured application and module routes.  This module utilizes the [v2.0 OpenAPI Specification]([https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md])

## License
Apache License, Version 2.0.

## IMPORTANT LINKS
- https://github.com/coldbox-modules/cbSwagger

## SYSTEM REQUIREMENTS
- Adobe CF 11+
- Lucee 4.5+
- ColdBox 4+

## Pre-requisites

To operate, the module requires that SES routing be enabled in your application.  For more information [read the official documentation](https://coldbox.ortusbooks.com/content/Routing/routes_configuration.html).

## Install cbSWagger ( via Commandbox )

`box install cbSwagger`

> Note:  Omit the `box` from your command, if you are already in the Commandbox interactive shell


## Configure cbSwagger to auto-detect your API Routes

By default, cbSwagger looks for routes beginning with `api`.  By adding a `cbSwagger` configuration key to your Coldbox configuration, you can add additional metadata to the OpenAPI JSON produced by the module entry point.  A full configuration example is provided below:

```js
cbswagger = {
	// The route prefix to search.  Routes beginning with this prefix will be determined to be api routes
	"routes" : [ "api" ],
	// A base path prefix for your API - leave blank if all routes are configured to the root of the site
	"basePath" : "/",
	// The API host
	"host" : "",
	// The transfer protocol of the API Values must be from: http, https, ws, wss
	"schemes" : [ "https", "http" ],
	// Information about your API
	"info" : {
		//The contact email address
		"contact" : {
			"name" : "API Support",
			"url" : "https://mysite.com",
			"email" : "support@ortussolutions.com"
		},
		//A title for your API
		"title":"",
		//A descritpion of your API
		"description":"",
		//A url to the License of your API
		"license" : {
			"name": "Apache 2.0",
			"url": "http://www.apache.org/licenses/LICENSE-2.0.html"
		},
		//A terms of service URL for your API
		"termsOfService" : "http://swagger.io/terms/",
		//The version of your API
		"version" : "v1"
	},
	//An array of all of the request body formats your your API is configured to consume
	"consumes": ["application/json","multipart/form-data","application/x-www-form-urlencoded"],
	//An array of all of the response body formats your API delivers
	"produces": ["application/json"],
	"securityDefinitions" : {
		"tokenAuthentication" : {
			"description":"Authentication provided by an API key.  This security scheme is stateless.  The header value must be in a space-delimited format with the token in the second index position",
			"type"       : "apiKey",
			"name"       : "Authorization",
			"in"         : "header",
			"example"    : "Bearer abcdefg1234567zyx"
	    }
	}
};

```

## Handler Introspection & Documentation attributes

cbSwagger will automatically introspect your API handlers provided by your routing configuration.  You may provide additional function attributes, which will be picked up and included in your documentation.  The content body of these attributes may be provided as JSON, plain text, or may provided a file pointer which will be included as a `$ref` attribute.  Some notes on function attributes:

* Metadata attributes using a `response-` prefix in the annotation will be parsed as responses.   For example `@response-200 { "description" : "User successfully updated", "schema" : "/includes/resources/schema.json##user" }` would populate the `200` responses node for the given method ( in this case, `PUT /api/v1/users/:id` ). If the annotation text is not valid JSON or a file pointer, this will be provided as the response description.
* Metadata attributes prefixed with `param-` will be included as paramters to the method/action.  Example: `@param-firstname { "type": "string", "required" : "false", "in" : "query" }` If the annotation text is not valid JSON or a file pointer, this will be provided as the parameter description and the parameter requirement will be set to `false`.
* Parameters provided via the route ( e.g. the `id` in `/api/v1/users/:id` ) will always be included in the array of parameters as required for the method.  Annotations on those parameters may be used to provide additional documentation.
* You may also provide paths to JSON files which describe complex objects which may not be expressed within the attributes themselves.  This is ideal to provide an endpoint for [parameters](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/2.0.md#parameterObject) and [responses](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#responseObject)  If the atttribute ends with `.json`, this will be included in the generated OpenAPI document as a [$ref include](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/2.0.md#pathItemObject).
* Attributes which are not part of the swagger path specification should be prefixed with an `x-`, [x-attributes](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#specificationExtensions) are an official part of the OpenAPI Specification and may be used to provide additional information for your developers and consumers
* `hint` attributes, provided as either comment `@` annotations or as function body attributes will be treaded as the description for the method 
* `description` due to variances in parsing comment annotations, `description` annotations must be provided as attributes of the function body.  For example, you would use `function update( event, rc, prc ) description="Updates a user"{}` rather than `@description Updates a user`

*Basic Example:*


```js
//(POST) /api/v1/users
function add( event, rc, prc )
	description="Adds a new user"
	parameters="/includes/resources/users.add.parameters.json"
	responses="/includes/resources/users.add.responses.json"
	x-SomeAdditionalInfo="Here is some additional information on this path"
{

	...[ Your code here ]...

}
```

*Example using file pointers:*

```js
/**
* @hint Adds a new user
* @x-parameters /includes/resources/users.add.parameters.json##user
* @responses /includes/resources/users.add.responses.json
* @x-SomeAdditionalInfo Here is some additional information on this path
*/
function add( event, rc, prc ){

	...[ Your code here ]...

}

```

*Example using JSON ( + file pointers )*

```js
/**
* @param-firstname { "type": "string", "required" : "false", "in" : "query" }
* @param-lastname { "type": "string", "required" : "false", "in" : "query" }
* @param-email { "type": "string", "required" : "false", "in" : "query" }
* @response-200 { "description" : "User successfully updated", "schema" : "/includes/resources/schema.json##user" }
**/
function update( event, rc, prc ) description="Updates a user"{

	...[ Your code here ]...

}
```

********************************************************************************
Copyright Since 2016 Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************

#### HONOR GOES TO GOD ABOVE ALL

Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the
Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD

 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
