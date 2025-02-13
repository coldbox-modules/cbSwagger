component name="OpenAPIConstraintsGenerator" {

	property name="cache" inject="cachebox:template";

	public struct function generateConstraintsFromOpenAPISchema(
		string parametersPath  = "",
		string requestBodyPath = "",
		boolean discoverPaths  = true,
		string callingFunctionName
	){
		var paths = _discoverPaths( argumentCollection = arguments );

		var constraints = {};

		if ( paths.parametersPath != "" ) {
			var parametersJSON = variables.cache.getOrSet(
				paths.parametersPath,
				() => {
					return deserializeJSON( fileRead( expandPath( paths.parametersPath ) ) );
				},
				1 // 1 day
			);
			structAppend( constraints, generateConstraintsFromParameters( parametersJSON[ paths.parametersKey ] ) )
		}

		if ( paths.requestBodyPath != "" ) {
			var requestBodyJSON = variables.cache.getOrSet(
				paths.requestBodyPath,
				() => {
					return deserializeJSON( fileRead( expandPath( paths.requestBodyPath ) ) );
				},
				1 // 1 day
			);
			var schema = requestBodyJSON[ "content" ][ "application/json" ][ "schema" ];
			structAppend(
				constraints,
				generateConstraintsFromRequestBodyProperties( schema.properties, schema.required )
			);
		}

		return constraints;
	}

	private struct function generateConstraintsFromParameters( required array parameters ){
		return arguments.parameters.reduce( ( allConstraints, parameter ) => {
			allConstraints[ parameter.name ] = generateConstraint(
				schema     = ( parameter.schema ?: {} ),
				isRequired = ( parameter.required ?: false )
			);
			return allConstraints;
		}, {} );
	}

	private struct function generateConstraintsFromRequestBodyProperties(
		required struct properties,
		required array requiredFields
	){
		return arguments.properties.map( ( fieldName, schema ) => {
			return generateConstraint(
				schema     = schema,
				isRequired = arrayContainsNoCase( requiredFields, fieldName ) > 0
			);
		} );
	}

	private struct function generateConstraint( required struct schema, required boolean isRequired ){
		var constraints           = {};
		constraints[ "required" ] = arguments.isRequired;
		addValidationType( constraints, schema );
		if ( constraints[ "type" ] == "struct" && schema.keyExists( "properties" ) ) {
			constraints[ "constraints" ] = generateConstraintsFromRequestBodyProperties(
				schema.properties,
				schema.required ?: []
			);
		}
		if ( constraints[ "type" ] == "array" && schema.keyExists( "items" ) ) {
			constraints[ "items" ] = generateConstraint( schema.items, arguments.isRequired );
		}
		if ( schema.keyExists( "enum" ) ) {
			constraints[ "inList" ] = arrayToList( schema[ "enum" ] );
		}
		if ( schema.keyExists( "minimum" ) ) {
			constraints[ "min" ] = schema[ "minimum" ];
		}
		if ( schema.keyExists( "maximum" ) ) {
			constraints[ "max" ] = schema[ "maximum" ];
		}
		if ( schema.keyExists( "default" ) ) {
			constraints[ "defaultValue" ] = schema[ "default" ];
		}
		if ( schema.keyExists( "minLength" ) || schema.keyExists( "maxLength" ) ) {
			param schema.minLength = "";
			param schema.maxLength = "";
			constraints[ "size" ]  = "#schema.minLength#..#schema.maxLength#";
		}
		if ( schema.keyExists( "x-coldbox-additional-validation" ) ) {
			structAppend( constraints, schema[ "x-coldbox-additional-validation" ] );
		}
		for (
			var c in [
				"after",
				"afterOrEqual",
				"before",
				"beforeOrEqual",
				"dateEquals"
			]
		) {
			if ( constraints.keyExists( c ) && constraints[ c ] == "now" ) {
				constraints[ c ] = now();
			}
		}
		return constraints;
	}

	private string function addValidationType( required struct constraints, required struct metadata ){
		param arguments.metadata.type   = "";
		param arguments.metadata.format = "";
		switch ( arguments.metadata.type ) {
			case "integer":
				arguments.constraints[ "type" ] = "integer";
				break;
			case "number":
				switch ( arguments.metadata.format ) {
					case "double":
					case "float":
						arguments.constraints[ "type" ] = "float";
						break;
					default:
						arguments.constraints[ "type" ] = "numeric";
						break;
				}
				break;
			case "boolean":
				arguments.constraints[ "type" ] = "boolean";
				break;
			case "array":
				arguments.constraints[ "type" ] = "array";
				break;
			case "object":
				arguments.constraints[ "type" ] = "struct";
				break;
			case "string":
				switch ( arguments.metadata.format ) {
					case "date-time-without-timezone":
						arguments.constraints[ "type" ] = "date";
						break;
					default:
						arguments.constraints[ "type" ] = "string";
						break;
				}
				break;
		}
	}

	private struct function _discoverPaths(
		string parametersPath  = "",
		string requestBodyPath = "",
		boolean discoverPaths  = true,
		string callingComponent,
		string callingFunctionName
	){
		var parametersKey = "parameters";
		if ( arguments.parametersPath != "" ) {
			parametersKey            = listLast( arguments.parametersPath, "####" );
			arguments.parametersPath = reReplaceNoCase(
				listFirst( arguments.parametersPath, "####" ),
				"^~",
				"/resources/apidocs/"
			);
			if ( parametersKey == "" ) {
				parametersKey = "parameters";
			}
		}

		if ( arguments.discoverPaths ) {
			if ( arguments.parametersPath == "" || arguments.requestBodyPath == "" ) {
				param variables.localActions = getMetadata( variables.$parent ).functions;
				if ( isNull( arguments.callingFunctionName ) ) {
					var stackFrames = callStackGet();
					for ( var stackFrame in stackFrames ) {
						if (
							!arrayContains(
								[
									"_discoverPaths",
									"generateConstraintsFromOpenAPISchema",
									"getByDelegate"
								],
								stackFrame[ "function" ]
							)
						) {
							arguments.callingFunctionName = stackFrame[ "function" ];
							break;
						}
					}
				}
				var callingFunction = variables.localActions.filter( ( action ) => {
					return action.name == callingFunctionName;
				} );
				if ( !callingFunction.isEmpty() ) {
					if ( arguments.parametersPath == "" && callingFunction[ 1 ].keyExists( "x-parameters" ) ) {
						parametersKey            = listLast( callingFunction[ 1 ][ "x-parameters" ], "####" );
						arguments.parametersPath = reReplaceNoCase(
							listFirst( callingFunction[ 1 ][ "x-parameters" ], "####" ),
							"^~",
							"/resources/apidocs/"
						);
					}
					if ( arguments.requestBodyPath == "" && callingFunction[ 1 ].keyExists( "requestBody" ) ) {
						arguments.requestBodyPath = reReplaceNoCase(
							listFirst( callingFunction[ 1 ][ "requestBody" ], "####" ),
							"^~",
							"/resources/apidocs/"
						);
					}
				}
			}
		}

		return {
			"parametersPath"  : arguments.parametersPath,
			"parametersKey"   : parametersKey,
			"requestBodyPath" : arguments.requestBodyPath
		};
	}

}
