<cfcomponent extends="farcry.core.packages.formtools.arrayupload" output="false" persistent="false">
	
	<cffunction name="handleFilePost" access="public" output="false" returntype="struct" hint="Handles image post and returns standard formtool result struct">
		<cfargument name="objectid" type="uuid" required="true" hint="The objectid of the edited object" />
		<cfargument name="existingfile" type="string" required="false" default="" hint="Current value of property" />
		<cfargument name="uploadfield" type="string" required="true" hint="Traditional form saves will use <PREFIX><PROPERTY>NEW, ajax posts will use <PROPERTY>NEW ... so the caller needs to say which it is" />
		<cfargument name="destination" type="string" required="true" hint="Destination of file" />
		<cfargument name="location" type="string" required="true" hint="Destination of file" />
		<cfargument name="allowedExtensions" type="string" required="true" hint="The acceptable extensions" />
		<cfargument name="sizeLimit" type="string" required="false" default="0" hint="Maximum file size accepted" />
		<cfargument name="stFieldPost" type="struct" required="false" default="#structnew()#" hint="The supplementary data" />
		
		<cfset var uploadFileName = "" />
		<cfset var archivedFile = "" />
		<cfset var stResult = passed(arguments.existingfile) />
		<cfset var stFile = structnew() />
		<cfset var sourceFile = "" />
		<cfset var transformation = "" />
		
		<cfparam name="stFieldPost.UPLOAD" default="" />
		<cfparam name="stFieldPost.NEW" default="" />
		<cfparam name="stFieldPost.DELETE" default="false" /><!--- Boolean --->
		
		<cfset stResult.bChanged = false />
		
		<!--- If developer has entered an ftDestination, make sure it starts with a slash --->
		<cfif len(arguments.destination) AND left(arguments.destination,1) NEQ "/">
			<cfset arguments.destination = "/#arguments.destination#" />
		</cfif>
		
		<cfif location eq "images" >
			
			<!--- source=xxx => original file for this image; _source=xxx => temporary variable used for dependant cuts --->
			<cfif refindnocase("//res.cloudinary.com/.*\?source=",arguments.existingfile)>
				<cfset sourceFile = application.formtools.image.oFactory.getCloudinarySource(arguments.existingfile) />
			<cfelseif len(arguments.existingfile) and not refindnocase("//res.cloudinary.com/",arguments.existingfile) and application.fc.lib.cdn.ioFileExists(location="images",file=arguments.existingfile)>
				<cfset sourceFile = arguments.existingfile />
			</cfif>
			
			<cfif ((structkeyexists(form,arguments.uploadfield) and len(form[arguments.uploadfield])) or (isBoolean(stFieldPost.DELETE) and stFieldPost.DELETE)) and len(sourceFile)>
				
				<cfset archivedFile = application.fc.lib.cdn.ioMoveFile(source_location="images",source_file=sourceFile,dest_location="archive",dest_file="#arguments.destination#/#arguments.objectid#-#DateDiff('s', 'January 1 1970 00:00', now())#-#listLast(sourceFile, '/')#") />
				<cfset stResult = passed("") />
			    <cfset stResult.bChanged = true />
			    
			</cfif>
			
		  	<cfif structkeyexists(form,arguments.uploadfield) and len(form[arguments.uploadfield])>
				
		    	<cfif len(sourceFile)>
		    		
					<!--- This means there is already a file associated with this object. The new file must have the same name. --->
					<cftry>
						<cfset uploadFileName = application.fc.lib.cdn.ioUploadFile(location="images",destination=sourceFile,nameconflict="makeunique",field=arguments.uploadfield,sizeLimit=arguments.sizeLimit) />
						
						<!--- Copy to Cloudinary --->
						<cfif refindnocase("//res.cloudinary.com/",arguments.existingfile)>
							<cfset stFile = application.formtools.image.oFactory.uploadToCloudinary(file=uploadFileName,publicID=getCloudinaryID(arguments.existingfile)) />
						<cfelse>
							<cfset stFile = application.formtools.image.oFactory.uploadToCloudinary(file=uploadFileName) />
						</cfif>
						<cfset uploadFileName = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(uploadFileName)#" />
						
						<cfset stResult = passed(uploadFileName) />
						<cfset stResult.bChanged = true />
						
						<cfcatch type="uploaderror">
							<cfset application.fc.lib.cdn.ioMoveFile(source_location="archive",source_file=archivedFile,dest_location="images",dest_file=sourceFile) />
							<cfset stResult = failed(value=arguments.existingfile,message=cfcatch.message) />
						</cfcatch>
					</cftry>
					
				<cfelse>

					<!--- There is no image currently so we simply upload the image and make it unique  --->
					<cftry>
						<cfset uploadFileName = application.fc.lib.cdn.ioUploadFile(location="images",destination=arguments.destination,nameconflict="makeunique",acceptextensions=arguments.allowedExtensions,field=arguments.uploadfield,sizeLimit=arguments.sizeLimit) />
						
						<!--- Copy to Cloudinary --->
						<cfset stFile = application.formtools.image.oFactory.uploadToCloudinary(uploadFileName) />
						<cfset uploadFileName = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(uploadFileName)#" />
						
						<cfset stResult = passed(uploadFileName) />
						<cfset stResult.bChanged = true />
						
						<cfcatch type="uploaderror">
							<cfset stResult = failed(value=arguments.existingfile,message=cfcatch.message) />
						</cfcatch>
					</cftry>
					
				</cfif>
				
			</cfif>

		<cfelse>

			<cfif structkeyexists(form,arguments.uploadfield) and len(form[arguments.uploadfield])>
	  		
				<cftry>
					<cfset uploadFileName = application.fc.lib.cdn.ioUploadFile(location=arguments.location,destination=arguments.destination,acceptextensions=arguments.allowedExtensions,field=arguments.uploadfield,sizeLimit=arguments.sizeLimit,nameconflict="makeunique") />
					<cfset stResult = application.formtools.field.oFactory.passed(uploadFileName) />
					
					<cfcatch type="uploaderror">
						<cfset stResult = application.formtools.field.oFactory.failed(value=arguments.existingfile,message=cfcatch.message) />
					</cfcatch>
				</cftry>
				
			</cfif>

		</cfif>
		
		<cfreturn stResult />
	</cffunction>

</cfcomponent>