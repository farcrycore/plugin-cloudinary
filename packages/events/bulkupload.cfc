<cfcomponent displayname="Bulk Upload" hint="Bulk upload tasks" output="false" persistent="false">
	
	<cffunction name="uploadfilecopied" access="public" output="false" returntype="void">
		<cfargument name="taskID" type="string" required="true" />
		<cfargument name="jobID" type="string" required="true" />
		<cfargument name="action" type="string" required="true" />
		<cfargument name="ownedBy" type="string" required="true" />
		<cfargument name="details" type="any" required="true" />
		
		<cfset var stFile = structnew() />
		<cfset var stObject = arguments.details.stObject />
		
		<cftry>
			<!--- Copy to Cloudinary --->
			<cfset stFile = application.formtools.image.oFactory.uploadToCloudinary(stObject[arguments.details.targetfield]) />
			<cfset stObject[arguments.details.targetfield] = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(stObject[arguments.details.targetfield])#" />
			
			<cfcatch type="uploaderror">
				<cflog file="bulkupload" type="error" application="true" text="#serializeJSON(cfcatch)#" />
			</cfcatch>
		</cftry>
	
	</cffunction>
	
</cfcomponent>