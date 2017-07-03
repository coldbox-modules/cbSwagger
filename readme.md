[![Build Status](https://travis-ci.org/coldbox-modules/cbSwagger.svg?branch=development)](https://travis-ci.org/coldbox-modules/cbSwagger)

# Welcome to the Coldbox Swagger Module
This module automatically generates OpenAPI ( fka Swagger ) documenation from your configured application and module routes.  This module utilizes the [v3.0 OpenAPI Specification]([https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md])

## License
Apache License, Version 2.0.

## IMPORTANT LINKS
- https://github.com/coldbox-modules/cbSwagger

## SYSTEM REQUIREMENTS
- Adobe CF 10+
- Lucee 4.5+
- ColdBox 4+

## Pre-requisites

To operate, the module requires that SES routing be enabled in your application.  For more information [read the official documentation](https://coldbox.ortusbooks.com/content/Routing/routes_configuration.html).

## Install cbSWagger ( via Commandbox )

`box install cbswagger`

> Note:  Omit the `box` from your command, if you are already in the Commandbox interactive shell


## Configure cbSwagger to auto-detect your API Routes

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

## Handler Introspection & Documentation attributes

cbSwagger will automatically introspect your API handlers provided by your routing configuration.  You may provide additional function attributes, which will be picked up and included in your documentation.  Some notes on function attributes:

* Attributes which are not part of the swagger path specification should be prefixed with an `x-`, [x-attributes](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#specificationExtensions) are an official part of the OpenAPI Specification and may be used to provide additional information for your developers and consumers
* You may also provide paths to JSON files which describe complex objects which may not be expressed within the attributes themselves.  This is ideal to provide an endpoint for [parameters](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#parameterObject) and [responses](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#responseObject)  If the atttribute ends with `.json`, this will be included in the generated OpenAPI document as a [$ref include](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md#pathItemObject).

Example:


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



********************************************************************************
Copyright Since 2016 Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
####HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the
Holy Ghost which is given unto us. ." Romans 5:5

###THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
