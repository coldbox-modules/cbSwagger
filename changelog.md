CHANGELOG
=========

## 1.2.1
* Fixes a bug where an error was thrown when an api route does not contain a handler
* Implements parsing of Coldbox route parameter types

## 1.2.0

* Adds new function metadata handling for parameters and responses
* Auto maps hints provided in function metadata to as method descriptions

## 1.1.2

* Add `$ref` sanitization and inherited metadata introspection
* Add the ability to handle arrays returned from `$ref` keys. Prepends moudule routing to operation id
* ACF syntax corrections and add better throw for attempts to parse component with syntax errors


## 1.1.0

* Normalization to new module templates
* HTTP Verbs should be lower case [#1](https://github.com/coldbox-modules/cbSwagger/issues/1)


## 1.0.3

* Exception when `handler` or `module` does not exist in a route.

## 1.0.2

* Overall syntax Ortus standards
* Some var scoping issues
* Added persistence and injections to services
* Added more documentation to handler, services and readme
* Added swagger-sdk as a module dependency

## 1.0.1

* Add module introspection
* Forgebox integration updates

## 1.0.0

* Initial Module Release
