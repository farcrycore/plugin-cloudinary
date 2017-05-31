<!--- @@displayname: Cloudinary Migrator - Images --->
<!--- @@fuAlias: migrator --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<cfparam name="URL.typename"    default="">
<cfparam name="URL.property"   default="">
<cfparam name="URL.sourceimage" default="">

<cfscript>
	try {
		request.mode.ajax = true;
		REQUEST.mode.BADMIN = FALSE;
		
		statusCode = 200;
		aResults = [];

		for (typename in application.stCOAPI) {
			stTable = {};
			
			if (URL.typename  == "" OR (URL.typename != "" AND URL.typename == typename )) 	{
				stTable['name'] = typename;
				stTable['PACKAGE'] =  application.stCOAPI[typename]['PACKAGE'];	
stTable['applicationname'] = APPLICATION.applicationname;
				if ( ! ListContainsNoCase('forms', application.stCOAPI[typename]['PACKAGE'])) {
					stProperties = application.stCOAPI[typename]['stProps'];
	
					stTable['checkStatus'] = StructKeyExists(stProperties, 'status');		
					stTable['properties'] = stProperties.Reduce(function(aReturn, key, stProperty) {
						
						if ( (StructKeyExists(stProperty['METADATA'], 'fttype') && ListContainsNoCase('image,s3upload', stProperty['METADATA']['fttype'])  ) || (StructKeyExists(stProperty['METADATA'], 'ftLocation') && ListContainsNoCase('images', stProperty['METADATA']['ftLocation']) )) {

/*							
// adNews - yafAgency, yafBrand | bannerimage and bannersourceimage
	if ( APPLICATION.applicationname == 'adnews' AND ListFindNoCase('yafAgency,yafBrand', typename) GT 0 AND ListFindNoCase('bannerimage,bannersourceimage', key) GT 0 )
		StructDelete(stProperty['METADATA'], 'ftSourceField', false);
*/
							if ( (URL.property == "" OR (URL.property != "" AND URL.property == key)) AND (sourceimage == "" OR (URL.sourceimage != "" AND URL.sourceimage != StructKeyExists(stProperty['METADATA'], 'ftSourceField')))) {
								stImage = {};
								stImage['name'] = key;
				
								if (StructKeyExists(stProperty['METADATA'], 'ftDestination'))
									stImage['path'] = stProperty['METADATA']['ftDestination'];
								else
									stImage['path'] = '';
									
								stImage['sourceImage'] = ! StructKeyExists(stProperty['METADATA'], 'ftSourceField'); // source or crop

				
		/*AJM: for debugging*/		
		stImage['fttype'] = stProperty['METADATA']['fttype'];
		if (StructKeyExists(stProperty['METADATA'], 'ftLocation'))
			stImage['ftLocation'] = stProperty['METADATA']['ftLocation'];		
				
								return aReturn.append(stImage);
							} 
							else {
								return aReturn;
							} // URL.property
						}
						else {
							return aReturn;
						}
						
					}, []);
			
					if (stTable['properties'].len())
						aResults.Append(stTable);
				} // packages
			} // URL.typename	
		} // application.stCOAPI
	
	}
	catch (any error) {
		statusCode = 500;
		aResults = error;
	}

	content reset="true" type="application/json";
	header statuscode="#statusCode#";
	writeoutput(serializeJSON(aResults));
	
	// Farcry 7 application.fapi.stream(content=aResults, type="json");
</cfscript>