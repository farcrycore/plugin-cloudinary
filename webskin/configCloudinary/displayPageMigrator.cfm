<!--- @@displayname: Cloudinary Migrator - Images --->
<!--- @@fuAlias: migrator --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<cfscript>
	try {
		request.mode.ajax = true;
		REQUEST.mode.BADMIN = FALSE;
		
		statusCode = 200;
		aResults = [];

		for (typename in application.stCOAPI) {
			stTable = {};
			stTable['name'] = typename;
			stTable['PACKAGE'] =  application.stCOAPI[typename]['PACKAGE'];	

			if ( ! ListContainsNoCase('forms', application.stCOAPI[typename]['PACKAGE'])) {
				stProperties = application.stCOAPI[typename]['stProps'];

				stTable['checkStatus'] = StructKeyExists(stProperties, 'status');		
				stTable['properties'] = stProperties.Reduce(function(aReturn, key, stProperty){
					if ( (StructKeyExists(stProperty['METADATA'], 'fttype') && ListContainsNoCase('image,s3upload', stProperty['METADATA']['fttype'])  ) || (StructKeyExists(stProperty['METADATA'], 'ftLocation') && ListContainsNoCase('images', stProperty['METADATA']['ftLocation']) )) {
					
						stImage = {};
						stImage['name'] = key;
		
						if (StructKeyExists(stProperty['METADATA'], 'ftDestination'))
							stImage['path'] = stProperty['METADATA']['ftDestination'];
						else
							stImage['path'] = '';
							
/*AJM: for debugging*/		
stImage['fttype'] = stProperty['METADATA']['fttype'];
if (StructKeyExists(stProperty['METADATA'], 'ftLocation'))
	stImage['ftLocation'] = stProperty['METADATA']['ftLocation'];		
		
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