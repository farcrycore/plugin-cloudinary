<!--- @@displayname: Cloudinary Migrator - Image Matrix Report --->
<!--- @@fuAlias: report-image --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<h1>Image Matrix Report </h1>

<cfset REQUEST.mode.BADMIN = FALSE>
<cfset urlPlugin = "http://#cgi.http_host#/cloudinary/"> <!--- application.config.cloudinary. --->

<cfscript>
		public struct function getCloudinaryImages() {
		var stCloudinary = {};
		var stResults    = {};
		
		try {
		
			stResults.ts = Now();
			
			http
				url="#urlPlugin#/migrator"
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
			dump(var=error, label="prcessor.getCloudinaryImages()", abort=true);
		}
		
		return stResults;
	}
	

</cfscript>



<cfset stImages = getCloudinaryImages()>
<cfset totalImageCount = 0>
<cfoutput>
	<cfloop array="#stImages.ACLOUDINARYIMAGES#" index="stTypes">
		<span style="display: inline-block; width: 300px; font-weight: bold;">#stTypes.name#<br /><br /></span>
		<cfloop array="#stTypes.properties#" index="stProperty">
			<cfquery datasource="#APPLICATION.dsn#" name="qryImage" maxrows="20">
				select count(*) as cnt
				from #stTypes.name#
				where #stProperty.name# like '%res.cloudinary.com%'
			</cfquery>
			<cfset totalImageCount += qryImage.cnt>
			<span  style="display: inline-block; width: 300px;">#stProperty.name#<br />#NumberFormat(qryImage.cnt, '999,999,999')#<br /></span>
		</cfloop>
		<hr>
	</cfloop>
	
	<h2>Total Images: #NumberFormat(totalImageCount, '999,999,999')#</h2>
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
