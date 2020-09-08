# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [2.3.0] => 2020-SEP-08

### Added

* Add CORS support for cbswagger endpoint #25 

----

## [2.2.1] => 2020-MAY-12

### Fixed

* On lucee the `displayName` defaults to `Component`, skipping this default to select the correct `operationId` for the resource
* The `moduleName` hint for the `appendFunctionInfo` was mispelled

----

## [2.2.0] => 2020-MAY-12

### Added

* When defining external files in annotations, you can now prefix them with `~` and this will expand to the module setting of `samplesPath`. This way you can write your annotations in a more cleaner manner.
* Auto-publishing of changelog's to github
* New changelog looks according to keepachangelog.com
  
----

## [2.1.1] => 2020-MAY-06

* Updates to support ColdBox 6

----

## [2.1.0] => 2020-APR-16

### Features

* Allow `@security` annotation to override the security mechanisms defined in config. The value can be a JSON array of security directives, a file pointer, or for convenience the name of a security schema. See readme for examples.
* Support for discovering responses and examples by conventions in the `resources/apidocs` folder convention. See readme for examples.
* Ability to exclude routes from the generated spec via the `excludeRoutes` configuration key.

### Improvements

* Add default `samplesPath` config item to `resources/apidocs` in the ModuleConfig
* Add convention samples parsing and refactor segment parsing to separate methods

### Bugs

* Fixes for new router syntax not parsing actions correctly or not taking into account actions attached to verbs

----

## [2.0.0] => 2019-SEP-02

* `feature`: Upgraded to swagger-sdk 2.0.0 to support OpenAPI 3.0.x. A great guide on migrating is here: https://blog.readme.io/an-example-filled-guide-to-swagger-3-2/
* Migrated `cbSwagger` settings to the `moduleSettings` struct instead of top-level in the `config/ColdBox.cfc`. Make sure you move your settings.
* `feature` : You can now pass a `format` to the `/cbSwagger` endpoint to either get the OpenAPI doc as `json` or `yml`. Eg: `/cbswagger?format=yml`
* `feature` : You have two distinct routes for the json and yml formats: `/cbSwagger/json` and `/cbSwagger/yml`
* You can choose your default output format via the module settings: `defaultFormat` setting. Valid options are `json` and `yml`
* `features` : Support for ColdBox 5 event routing and response routing.

* `improvement` : You can now tag your handlers with a `displayName` that will be used for operation ID building
* `improvement` : Improved the way operation Ids are reported so they can be unique when reusing handler actions.
* `improvement` : Refactored `createLinkedHashMap()` -> `structNew( "ordered" )`
* `improvement`: Removed lucee 4.5, acf11 support.

----

## 1.4.1

* Fix for detecting ColdBox 5

----

## 1.4.0

* Update build process for new module standards
* ColdBox 5 Compatiblity for inherited entry points
* Non RESTFul action params where not being translated on routes.
* Fixed `int32` to `integer` on examples and tests so they can validate in the schema

----

## 1.3.0

* Added Editor standards
* Fix to modules invocation path on RouteParser when no cfmapping defined.
* Updates to readme
* Set the contact object and license object according to spec 2 defaults
* Default the API schemes to http/s
* Dropped cf10 from automated tests
* Added API Docs to S3 via Travis

----

## 1.2.1

* Fixes a bug where an error was thrown when an api route does not contain a handler
* Implements parsing of Coldbox route parameter types

----

## 1.2.0

* Adds new function metadata handling for parameters and responses
* Auto maps hints provided in function metadata to as method descriptions

----

## 1.1.2

* Add `$ref` sanitization and inherited metadata introspection
* Add the ability to handle arrays returned from `$ref` keys. Prepends moudule routing to operation id
* ACF syntax corrections and add better throw for attempts to parse component with syntax errors

----

## 1.1.0

* Normalization to new module templates
* HTTP Verbs should be lower case [#1](https://github.com/coldbox-modules/cbSwagger/issues/1)

----

## 1.0.3

* Exception when `handler` or `module` does not exist in a route.

----

## 1.0.2

* Overall syntax Ortus standards
* Some var scoping issues
* Added persistence and injections to services
* Added more documentation to handler, services and readme
* Added swagger-sdk as a module dependency

----

## 1.0.1

* Add module introspection
* Forgebox integration updates

----

## 1.0.0

* Initial Module Release
