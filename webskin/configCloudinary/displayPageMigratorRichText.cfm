<!--- @@displayname: Cloudinary Migrator - RichText --->
<!--- @@fuAlias: migrator-richtext --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<cfscript>
	try {
		REQUEST.mode.BADMIN = FALSE;
		
		statusCode = 200;
		aResults = [];

		for (typename in application.stCOAPI) {
			stTable = {};
			stTable['name'] = typename;
			stTable['PACKAGE'] =  application.stCOAPI[typename]['PACKAGE'];	

			if ( ! ListContainsNoCase('forms', application.stCOAPI[typename]['PACKAGE']) ) {
				stProperties = application.stCOAPI[typename]['stProps'];

				stTable['checkStatus'] = StructKeyExists(stProperties, 'status');		
				stTable['properties'] = stProperties.Reduce(function(aReturn, key, stProperty){
					if ( (StructKeyExists(stProperty['METADATA'], 'fttype') && ListContainsNoCase('richtext', stProperty['METADATA']['fttype'])  ) ) {
					
						stImage = {};
						stImage['name'] = key;
		
		
						return aReturn.append(stImage);
					}
					else 
						return aReturn;
				}, []);
		
				if (stTable['properties'].len())
					aResults.Append(stTable);
			} // packages
		} // application.stCOAPI
	
	}
	catch (any error) {
		statusCode = 500;
		aResults = error;
	}

	content reset="true" type="application/json";
	header statuscode="#statusCode#";
	WriteOutput(serializeJSON(aResults));
</cfscript>