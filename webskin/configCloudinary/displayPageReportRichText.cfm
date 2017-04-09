<!--- @@displayname: Cloudinary Migrator - Report RichText with cloudinary links --->
<!--- @@fuAlias: report-richtext --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->
<!--- @@Viewstack: any --->

<h1>Look for Cloudinary Links in RichText properties</h1>

<cfset REQUEST.mode.BADMIN = FALSE>
<cfset urlPlugin = "http://#cgi.http_host#/cloudinary/"> <!--- application.config.cloudinary. --->

<cfscript>
		public struct function getCloudinaryRichTextMetadata() {
		var stCloudinary = {};
		var stResults    = {};
		
		try {
		
			stResults.ts = Now();
			
			http
				url="#urlPlugin#/migrator-richtext"
				method="GET"
				result="stCloudinary"
				throwonerror="false" 
			{};
			
			if ( StructKeyexists(stCloudinary, 'status_code') && stCloudinary['status_code'] == '200') {
				stResults.success           = true;
				stResults.aCloudinaryImages = deserializeJSON(stCloudinary['filecontent']);
			}
			else {
				stResults.success           = false;
				stResults.aCloudinaryImages              = [];
				stResults.stResonse         = stCloudinary;
			}
		
		} 
		catch (any error) {
			dump(var=error, label="prcessor.getCloudinaryMetadata()", abort=true);
		}
		
		return stResults;
	}
	
	public struct function getCloudinaryRichtextImages(struct stCloudinary=getCloudinaryMetadata()) {
		var stResult = {};
		var aImages  = [];
		
		stResult.success=true;
		
		try {
			var stCloudinaryMetadata = ARGUMENTS.stCloudinary;
			
			if (stCloudinaryMetadata.success) {
				
				stCloudinaryMetadata.aCloudinaryImages.Each(function(stProperty, i){
//dump(var=stProperty, abort =true);
					stProperty.properties.Each(function(stProp) {
						//dump(var=stProp, label='stProp', abort=false);
						
						try {
							var sqlImages = new Query();
							sqlImages.setDatasource(APPLICATION.dsn);
							
							var sqlStatement = "
								SELECT objectid, label, '#stProp.name#' as fieldName, `#stProp.name#` as name
								FROM #stProperty.name#
								WHERE `#stProp.name#` like :urlCloudinary
								 
							"; // AND locked = :locked
							if (stProperty.checkStatus)
								sqlStatement = sqlStatement & " AND status = :status";
			
							sqlImages.setSQL(sqlStatement);
							
							sqlImages.addParam(name="urlCloudinary", cfsqltype="cf_sql_varchar", value='%res.cloudinary.com%');
							// sqlImages.addParam(name="locked",        cfsqltype="cf_sql_bit",     value=0);
							sqlImages.addParam(name="status",        cfsqltype="cf_sql_varchar", value='approved');			
							var sqlImagesResult = sqlImages.execute().getResult();
							if (sqlImagesResult.RecordCount > 0) {
//dump(var=sqlImagesResult, label="#stProp.name#.#stProp.name#", abort="false");
								sqlImagesResult.Each(function(stRow){
									stRow['tableName']    = stProperty.name;
									stRow['checkStatus']  = stProperty.checkStatus;
									stRow['package']      = stProperty.package;
									
									stRow['fieldName']     = stProp.name;
									
									
									aImages.append(stRow);
								});	
							}
						}
						catch (any error) {
							dump(var=error, label='Error 3: getCloudinaryRichtextImages', abort=true);
							//stResults.success           = false;
							//stResults.aCloudinaryImages = [];
							//stResults.stResonse         = error
						}
	
					});  // properties
	
				}); // aCloudinaryImages
			} 
			else {
				dump(var=stCloudinaryMetadata, label='Error 2: getCloudinaryRichtextImages', abort=true);
				//stResults.success           = false;
				//stResults.aCloudinaryImages              = [];
				//stResults.stResonse         = stCloudinaryMetadata;
			}
			
		}
		catch (any error) {
			dump(var=error, label='Error 1: getCloudinaryRichtextImages', abort=true);
			//stResult.success=false;
			//aImages = [];
			//stResult.error = error;
		}
		
		stResult.aImages = aImages;	
		
		return stResult;
	}
	
	

</cfscript>

<cfset imageCount = 0>
<cfset uploadCount = 0>
<cfset fetchCount = 0>
<cfset otherCount = 0>

<cfset stCloudinaryRichTextMetadata = getCloudinaryRichTextMetadata()>
<!--- <cfdump var="#stCloudinaryRichTextMetadata#" label="stCloudinaryRichTextMetadata" expand="false"> --->

<cfset stCloudinaryRichtextImages = getCloudinaryRichtextImages(stCloudinaryRichTextMetadata)>


<cfloop array="#stCloudinaryRichtextImages.aImages#" item="stRichText">
	<!--- <cfdump var="#stRichText#" label="stRichText" abort="true"> --->
	<cfset aLinks = reFindNoCaseAll('src="(http:|https:){0,1}//res\.cloudinary\.com/.*?"', stRichText.name)>
	<cfset aLen = aLinks.len.len()>
	<cfif aLen GT 0>
		<cfoutput><h4>#stRichText.tablename#.#stRichText.fieldName#: #stRichText.label# [#stRichText.objectid#]</h4></cfoutput>
		
		<cfloop from="1" to="#aLen#" index="c">
			<cfif aLinks.pos[c] != 0 AND aLinks.len[c] != 0>
				<cfset imageCount++>
				<cfset urlImage = Mid(stRichText.name, aLinks.pos[c], aLinks.len[c])>
				<cfif FindNoCase('/fetch/', urlImage) != 0>
					<cfset fetchCount++ >
				<cfelseif FindNoCase('/upload/', urlImage) != 0>
					<cfset uploadCount++ >
				<cfelse>
					<cfset otherCount++>
				</cfif>
				<cfoutput>#htmlEditFormat(urlImage)#<br /></cfoutput>
			<cfelse>
				<cfoutput><span style="color:red">aLinks.pos[c]=#aLinks.pos[c]# | aLinks.len[c]=#aLinks.len[c]#</span><br /></cfoutput>
				<cfdump var="#aLinks#" label="aLinks">
				<cfdump var="#stRichText.name#" label="stRichText.name">
			</cfif>
		</cfloop>
	</cfif>
</cfloop>

<cfoutput>
	<h2>
		Total Images: #imageCount#<br />
		Upload Images: #uploadCount# <br />
		Fetch Images: #fetchCount# <br />
		Other Images: #otherCount# 
	</h2>
</cfoutput>


<cffunction name="reFindNoCaseAll" output="true" returnType="struct">
   <cfargument name="regex" type="string" required="yes">
   <cfargument name="text" type="string" required="yes">

   <!--- Define local variables --->	
   <cfset var results=structNew()>
   <cfset var pos=1>
   <cfset var subex="">
   <cfset var done=false>
	
   <!--- Initialize results structure --->
   <cfset results.len=arraynew(1)>
   <cfset results.pos=arraynew(1)>

   <!--- Loop through text --->
   <cfloop condition="not done">

      <!--- Perform search --->
      <cfset subex=reFindNoCase(arguments.regex, arguments.text, pos, true)>
      <!--- Anything matched? --->
      <cfif subex.len[1] is 0>
         <!--- Nothing found, outta here --->
         <cfset done=true>
      <cfelse>
         <!--- Got one, add to arrays --->
         <cfset arrayappend(results.len, subex.len[1])>
         <cfset arrayappend(results.pos, subex.pos[1])>
         <!--- Reposition start point --->
         <cfset pos=subex.pos[1]+subex.len[1]>
      </cfif>
   </cfloop>

   <!--- If no matches, add 0 to both arrays --->
   <cfif arraylen(results.len) is 0>
      <cfset arrayappend(results.len, 0)>
      <cfset arrayappend(results.pos, 0)>
   </cfif>

   <!--- and return results --->
   <cfreturn results>
</cffunction>
