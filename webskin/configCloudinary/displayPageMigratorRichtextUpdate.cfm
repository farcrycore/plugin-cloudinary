<!--- @@displayname: Cloudinary Migrator - Update Images in RichText Field --->
<!--- @@fuAlias: migrator-richtext-upate --->
<!--- /cloudinary/migrator-richtext-upate --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<!--- 
use Farcry setData() to update type's richtext field'
only accept method = POST
check  hash(objectid+typename+oldval+newval+cloudinarysecret)
 --->

<!--- todo: remove dev --->
<cfparam name="FORM.objectid" default="">
<cfparam name="FORM.typename" default="">
<cfparam name="FORM.field"    default="">
<cfparam name="FORM.urlOld"   default="">
<cfparam name="FORM.urlNew"   default="">
<cfparam name="FORM.hash"     default="">

<cfscript>
	boolean function findRecord
		(
			required string objectid,
			required string typename
		) 
	{
		var qryFind = new Query()
		    qryFind.setDatasource(APPLICATION.dsn);
			qryFind.setSQL("SELECT count(*) as cnt FROM refObjects where typename = :typename and objectid = :objectid");
			qryFind.addParam(name="typename", cfsqltype="cf_sql_varchar", value=ARGUMENTS.typename);
			qryFind.addParam(name="objectid", cfsqltype="cf_sql_varchar", value=ARGUMENTS.objectid);

		var qryFindResults = qryFind.execute().getResult();		
		return (qryFindResults.cnt == 1);
	}
	
	try {
		REQUEST.mode.BADMIN = FALSE;
		stReturn = {};		
		
		if ( cgi.request_method == 'POST') { 
			system            = createObject("java", "java.lang.System");
			cloudinarysecret  = system.getEnv("CLOUDINARY_API_SECRET");
			
			//test hash and no fields are blank
			if ( FORM.objectid != '' && FORM.typename != '' && FORM.field != '' && FORM.urlOld != '' && FORM.urlNew != '' && FORM.hash == hash(FORM.objectid&FORM.typename&FORM.field&FORM.urlOld&FORM.urlNew&cloudinarysecret)) {

				if ( findRecord(FORM.objectid,FORM.typename) ) {
					var stObj = application.fapi.getContentObject(FORM.objectid,FORM.typename);
		
					// full S3 URL
					FORM.urlNew = application.fc.lib.cdn.ioGetFileLocation(location="images",file=FORM.urlNew).path;
					
					var before = Duplicate(stObj[FORM.field]);
					   					    
					    stObj[FORM.field] = replace(stObj[FORM.field], FORM.urlOld, FORM.urlNew, 'ALL');
					    
					    // try without ?_source=
					    urlOldNoSource = ReReplaceNoCase(FORM.urlOld, '\?(_){0,1}source=.*?.#ListLast(FORM.urlNew, '.')#', '');
					    stObj[FORM.field] = replace(stObj[FORM.field], urlOldNoSource, FORM.urlNew, 'ALL');
					    
					     // Try Decode URL
					    stObj[FORM.field] = replace(stObj[FORM.field], urlDecode(FORM.urlOld), FORM.urlNew, 'ALL');
					    stObj[FORM.field] = replace(stObj[FORM.field], urlDecode(urlOldNoSource), FORM.urlNew, 'ALL');
					
					if (before != stObj[FORM.field]) {
						stObj['DATETIMELASTUPDATED'] = Now();
						stObj['LASTUPDATEDBY']       = 'Cloudinary Migrator';
						
						// remove any ?_source= htat may have been inserted by Farcry 
					    // maybe best not to - to aggressive
					    // now searches / repaces both links
					    // stObj[FORM.field] = ReReplaceNoCase(stObj[FORM.field], '\?{_}(0,1)source=.*?#ListLast(FORM.urlNew, '.')#', '', 'ALL');
						
						var auditNote = "Cloudinary Migrator: update image from '#FORM.urlOld#' to '# FORM.urlNew#'";
						var stUpdate = application.fapi.setData(objectid=FORM.objectid, typename=FORM.typename ,stProperties=stObj, auditNote=auditNote, bAudit=1);
						
						
						if (stUpdate.bSuccess) {
							// TODO: This might not actually be needed 
							application.fc.lib.objectbroker.RemoveFromObjectBroker(lobjectids=FORM.objectid, typename=FORM.typename);
							
							stReturn['statusCode'] = 200;
							stReturn['message']    = "OK";
							stReturn['detail']     = "#auditNote# for #FORM.objectid# in #FORM.typename#.#FORM.field#";
						} else {
							stReturn['statusCode'] = 500;
							stReturn['error']      = stUpdate;
							stReturn['detail']     = "TODO: better error handling required here";
						}
					}
					else {
						stReturn['statusCode'] = 412;
						stReturn['message']    = "Precondition Failed";
						stReturn['detail']     = "No image links to update for #FORM.objectid# in #FORM.typename#.#FORM.field# [From: #FORM.urlOld# To #FORM.urlNew#]";
					}
				}
				else {
					stReturn['statusCode'] = 404;
					stReturn['message']    = "Not Found";
					stReturn['detail']     = "No record in #FORM.typename# for objectID FORM.objectid";
				}
			}
			else {
				stReturn['statusCode'] = 400;
				stReturn['message']    = "Bad Request";
				stReturn['detail']     = "Hash() failed";
			}
		} 
		else {
			stReturn['statusCode'] = 405;
			stReturn['message']    ="Method Not Allowed";
			stReturn['detail']     = "";
		}
		
	
	}
	catch (any error) {
		stReturn['statusCode'] = 500;
		stReturn['message']    = error.message;
		stReturn['detail']     = error.detail;
		
		stReturn['form']       = FORM;
		stReturn['error']      = error;
	}

	content reset="true" type="application/json";
	header statuscode="#stReturn['statusCode']#";
	WriteOutput(serializeJSON(stReturn));
</cfscript>