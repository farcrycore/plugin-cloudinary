<cfcomponent extends="farcry.core.packages.formtools.image" output="false" persistent="false">
	
	<cfproperty name="ftShowMetadata" type="boolean" default="false" hint="If this is set to false, the file size and dimensions of the current image are not displayed to the user" />
	<cfproperty name="dbPrecision" type="string" default="640" />
	
	<cffunction name="edit" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var html = super.edit(argumentCollection=arguments) />

		<cfreturn rereplace(html, '<span class="image-filename">http%3A%2F%2F[^<]+%2F([^<]+)%2E(\w+)</span>', '<span class="image-filename">\1.\2</span>') />
	</cffunction>
		
	<cffunction name="ajax" output="false" returntype="string" hint="Response to ajax requests for this formtool">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<!--- NOTE: this function needs to be able to handle non-ajax responses --->
		<!--- The main purpose of this override is to fix the result["filename"] value --->

		<cfset var result = super.ajax(argumentCollection=arguments) />
		<cfset var callback = "" />
		<cfset var data = {} />
		<cfset var sourcePath = {} />

		<!--- Parse data produced by ajax --->
		<cfif refind("^([^\(]+)\((.*)\)$", result)>
			<cfset callback = rereplace(result, "^([^\(]+)\((.*)\)$", "\1") />
			<cfset result = rereplace(result, "^([^\(]+)\((.*)\)$", "\2") />
		</cfif>
		<cfif isjson(result)>
			<cfset data = deserializeJSON(result) />
		</cfif>

		<cfif isstruct(data) and structKeyExists(data, "value") and len(data.value)>
			<cfset sourcePath = application.fc.lib.cloudinary.getSource(data.value) />
			<cfset data["filename"] = listfirst(listlast(sourcePath,'/'),"?") />
			<cfset result = serializeJSON(data) />
		</cfif>

		<!--- Re-add callback --->
		<cfif len(callback)>
			<cfset result = callback & "(" & result & ")" />
		</cfif>

		<cfreturn result />
	</cffunction>

	<cffunction name="handleFilePost" access="public" output="false" returntype="struct" hint="Handles image post and returns standard formtool result struct">
		<cfargument name="objectid" type="uuid" required="true" hint="The objectid of the edited object" />
		<cfargument name="existingfile" type="string" required="true" hint="Current value of property" />
		<cfargument name="uploadfield" type="string" required="true" hint="Traditional form saves will use <PREFIX><PROPERTY>NEW, ajax posts will use <PROPERTY>NEW ... so the caller needs to say which it is" />
		<cfargument name="destination" type="string" required="true" hint="Destination of file" />
		<cfargument name="allowedExtensions" type="string" required="true" hint="The acceptable extensions" />
		<cfargument name="stFieldPost" type="struct" required="false" default="#structnew()#" hint="The supplementary data" />
		
		<cfset var uploadFileName = "" />
		<cfset var archivedFile = "" />
		<cfset var stResult = passed(arguments.existingfile) />
		<cfset var stFile = structnew() />
		<cfset var sourceFile = "" />
		<cfset var transformation = "" />
		
		<cfparam name="stFieldPost.NEW" default="" />
		<cfparam name="stFieldPost.DELETE" default="false" /><!--- Boolean --->
		
		<cfset stResult.bChanged = false />
		
		<!--- If developer has entered an ftDestination, make sure it starts with a slash --->
		<cfif len(arguments.destination) AND left(arguments.destination,1) NEQ "/">
			<cfset arguments.destination = "/#arguments.destination#" />
		</cfif>
		
		<!--- source=xxx => original file for this image; _source=xxx => temporary variable used for dependant cuts --->
		<cfif refindnocase("//res.cloudinary.com/.*\?source=",arguments.existingfile)>
			<cfset sourceFile = application.fc.lib.cloudinary.getSource(arguments.existingfile) />
		<cfelseif len(arguments.existingfile) and not refindnocase("//res.cloudinary.com/",arguments.existingfile) and application.fc.lib.cdn.ioFileExists(location="images",file=arguments.existingfile)>
			<cfset sourceFile = arguments.existingfile />
		</cfif>
		
		<cfif ((structkeyexists(form,arguments.uploadfield) and len(form[arguments.uploadfield])) or (isBoolean(stFieldPost.DELETE) and stFieldPost.DELETE)) and len(sourceFile)>
			
			<cfif application.fc.lib.cdn.ioFileExists(location="images",file=sourceFile)>
				<cfset archivedFile = application.fc.lib.cdn.ioMoveFile(source_location="images",source_file=sourceFile,dest_location="archive",dest_file="#arguments.destination#/#arguments.objectid#-#DateDiff('s', 'January 1 1970 00:00', now())#-#listLast(sourceFile, '/')#") />
			</cfif>
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
						<cfset uploadFileName = uploadToCloudinary(file=uploadFileName,publicID=application.fc.lib.cloudinary.getID(arguments.existingfile)) />
					<cfelse>
						<cfset uploadFileName = uploadToCloudinary(file=uploadFileName) />
					</cfif>
					
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
					<cfset uploadFileName = uploadToCloudinary(uploadFileName) />
					
					<cfset stResult = passed(uploadFileName) />
					<cfset stResult.bChanged = true />
					
					<cfcatch type="uploaderror">
						<cfset stResult = failed(value=arguments.existingfile,message=cfcatch.message) />
					</cfcatch>
				</cftry>
				
			</cfif>
			
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="handleFileLocal" access="public" output="false" returntype="struct" hint="Handles using a local file as the new image and returns standard formtool result struct">
		<cfargument name="objectid" type="uuid" required="true" hint="The objectid of the edited object" />
		<cfargument name="existingfile" type="string" required="true" hint="Current value of property" />
		<cfargument name="localfile" type="string" required="true" hint="The local file" />
		<cfargument name="destination" type="string" required="true" hint="Destination of file" />
		<cfargument name="allowedExtensions" type="string" required="true" hint="The acceptable extensions" />
		<cfargument name="sizeLimit" type="numeric" required="false" default="0" hint="Maximum size of file in bytes" />
		
		<cfset var uploadFileName = "" />
		<cfset var archivedFile = "" />
		<cfset var stResult = passed(arguments.existingfile) />
		<cfset var stFile = structnew() />
		<cfset var i = 0 />
		<cfset var sourceFile = "" />
		
		<cfset stResult.bChanged = false />
		
		<!--- If developer has entered an ftDestination, make sure it starts with a slash --->
		<cfif len(arguments.destination) AND left(arguments.destination,1) NEQ "/">
			<cfset arguments.destination = "/#arguments.destination#" />
		</cfif>
		
		<!--- source=xxx => original file for this image; _source=xxx => temporary variable used for dependant cuts --->
		<cfif refindnocase("//res.cloudinary.com/.*\?source=",arguments.existingfile)>
			<cfset sourceFile = application.fc.lib.cloudinary.getSource(arguments.existingfile) />
		<cfelseif len(arguments.existingfile) and not refindnocase("//res.cloudinary.com/",arguments.existingfile) and application.fc.lib.cdn.ioFileExists(location="images",file=arguments.existingfile)>
			<cfset sourceFile = arguments.existingfile />
		</cfif>
		
	  	<cfif fileexists(arguments.localfile)>
	  	
			<cfif len(sourceFile)>
				
				<cfset archivedFile = application.fc.lib.cdn.ioMoveFile(source_location="images",source_file=sourceFile,dest_location="archive",dest_file="#arguments.destination#/#arguments.objectid#-#DateDiff('s', 'January 1 1970 00:00', now())#-#listLast(sourceFile, '/')#") />
				<cfset stResult = passed("") />
			    <cfset stResult.bChanged = true />
	    		
				<cfset stFile = getFileInfo(arguments.localfile) />
				
				<cfif arguments.sizeLimit and arguments.sizeLimit lt stFile.filesize>
					<cfset application.fc.lib.cdn.ioMoveFile(source_location="archive",source_file=archivedFile,dest_location="images",dest_file=sourceFile) />
					<cfset stResult = failed(value=arguments.existingfile,message="#arguments.localfile# is not within the file size limit of #round(arguments.sizeLimit/1048576)#MB") />
				<cfelseif listlast(sourcefile,".") eq listlast(arguments.localfile,".")>
					<cfset application.fc.lib.cdn.ioMoveFile(source_localpath=arguments.localfile,dest_location="images",dest_file=arguments.destination & "/" & uploadFilenName) />
					
					<!--- Copy to cloudinary --->
					<cfset uploadFileName = "#arguments.destination#/#uploadFileName#" />
					<cfif refindnocase("//res.cloudinary.com/",arguments.existingfile)>
						<cfset uploadFileName = uploadtocloudinary(uploadFileName,application.fc.lib.cloudinary.getID(arguments.existingFile)) />
					<cfelse>
						<cfset uploadFileName = uploadtocloudinary(uploadFileName) />
					</cfif>
					
					<cfset stResult = passed(uploadFileName) />
					<cfset stResult.bChanged = true />
				<cfelse>
					<cfset application.fc.lib.cdn.ioMoveFile(source_location="archive",source_file=archivedFile,dest_location="images",dest_file=sourceFile) />
					<cfset stResult = failed(value=arguments.existingfile,message="Replacement images must have the same extension") />
				</cfif>
				
			<cfelse>
				
				<cfset stFile = getFileInfo(arguments.localfile) />
				
				<cfif arguments.sizeLimit and arguments.sizeLimit lt stFile.fileSize>
					<cfset stResult = failed(value=arguments.existingfile,message="#arguments.localfile# is not within the file size limit of #round(arguments.sizeLimit/1048576)#MB") />
				<cfelseif listFindNoCase(arguments.allowedExtensions,listlast(arguments.localfile,"."))>
					<cfset uploadFileName = application.fc.lib.cdn.ioMoveFile(source_localpath=arguments.localfile,dest_location="images",dest_file=arguments.destination & "/" & getFileFromPath(arguments.localfile),nameconflict="makeunique") />
					
					<cfset uploadFileName = uploadtocloudinary(uploadFileName) />
					
					<cfset stResult = passed(uploadFileName) />
					<cfset stResult.bChanged = true />
				<cfelse>
					<cfset stResult = failed(value="",message="Images must have one of these extensions: #arguments.allowedExtensions#") />
				</cfif>
				
			</cfif>
			
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="handleFileSource" access="public" output="false" returntype="struct" hint="Handles the alternate case to handleFileSubmission where the file is sourced from another property">
		<cfargument name="sourceField" type="string" required="true" hint="The source field to use" />
		<cfargument name="stObject" type="struct" required="true" hint="The full set of object properties" />
		<cfargument name="destination" type="string" required="true" hint="Destination of file" />
		<cfargument name="stFields" type="struct" required="true" hint="Full content type property metadata" />
		
		<cfset var sourceFieldName = "" />
		<cfset var libraryFieldName = "" />
		<cfset var stImage = structnew() />
		<cfset var sourcefilename = "" />
		<cfset var finalfilename = "" />
		<cfset var uniqueid = 0 />
		
		<cfif not len(arguments.sourceField) and structkeyexists(arguments.stObject,listfirst(arguments.sourceField,":")) and len(arguments.stObject[listfirst(arguments.sourceField,":")])>
			<cfreturn passed("") />
		<cfelse>
			<cfset sourceFieldName = listfirst(arguments.sourceField,":") />
			
			<!--- The source could be from an image library in which case, the source field will be in the form 'uuidField:imageLibraryField' --->
			<cfset libraryFieldName = listlast(arguments.sourceField,":") />
		</cfif>
		
		<!--- If developer has entered an ftDestination, make sure it starts with a slash --->
		<cfif len(arguments.destination) AND left(arguments.destination,1) NEQ "/">
			<cfset arguments.destination = "/#arguments.destination#" />
		</cfif>
		
		<!--- Get the source filename --->
		<cfif NOT isArray(arguments.stObject[sourceFieldName]) AND len(arguments.stObject[sourceFieldName])>
		    <cfif arguments.stFields[sourceFieldName].metadata.ftType EQ "uuid">
				<!--- This means that the source image is from an image library. We now expect that the source image is located in the source field of the image library --->
				<cfset stImage = application.fapi.getContentObject(objectid="#arguments.stObject[sourceFieldName]#") />
				<cfif structKeyExists(stImage, libraryFieldName) AND len(stImage[libraryFieldName])>
					<cfset sourcefilename = stImage[libraryFieldName] />
				</cfif>
			<cfelse>
				<cfset sourcefilename = arguments.stObject[sourceFieldName] />
			</cfif>
		<cfelseif isArray(arguments.stObject[sourceFieldName])>
			<!--- if this is array, use only first item for cropping --->
			<cfif arrayLen(arguments.stObject[sourceFieldName])>
				<cfset stImage = application.fapi.getContentObject(objectid="#arguments.stObject[sourceFieldName][1]#") />
				<cfset sourcefilename = stImage[libraryFieldName] />
			</cfif>
		<cfelse>
			<cfset sourcefilename = "" />
		</cfif>
		
		<!--- Copy the source into the new field --->
		<cfif len(sourcefilename) and refindnocase("//res.cloudinary.com/",sourcefilename)>
			<!--- source=xxx => original file for this image; _source=xxx => temporary variable used for dependant cuts --->
			<cfif refind("\?(source|_source)=",sourcefilename)>
				<cfreturn passed(rereplace(sourcefilename,"\?_?source=[^&]+","") & "?_source=" & application.fc.lib.cloudinary.getSource(sourcefilename)) />
			</cfif>
		<cfelseif len(sourcefilename) and application.fc.lib.cdn.ioFileExists(location="images",file=sourcefilename)>
			<cfset sourcefilename = application.fc.lib.cdn.ioCopyFile(source_location="images",source_file=sourcefilename,dest_location="images",dest_file=arguments.destination & "/" & listlast(sourcefilename,"\/"),nameconflict="makeunique",uniqueamong="images") />
		</cfif>

		<cfreturn passed(sourcefilename) />
	</cffunction>
	
	<cffunction name="GenerateImage" access="public" output="false" returntype="struct">
		<cfargument name="source" type="string" required="true" hint="The absolute path where the image that is being used to generate this new image is located." />
		<cfargument name="destination" type="string" required="false" default="" hint="The absolute path where the image will be stored." />
		<cfargument name="width" type="numeric" required="false" default="0" hint="The maximum width of the new image." />
		<cfargument name="height" type="numeric" required="false" default="0" hint="The maximum height of the new image." />
		<cfargument name="autoGenerateType" type="string" required="false" default="FitInside" hint="How is the new image to be generated (ForceSize,FitInside,Pad)" />
		<cfargument name="padColor" type="string" required="false" default="##ffffff" hint="If AutoGenerateType='Pad', image will be padded with this colour" />
		<cfargument name="customEffectsObjName" type="string" required="true" default="imageEffects" hint="The object name to run the effects on (must be in the package path)" />
		<cfargument name="lCustomEffects" type="string" required="false" default="" hint="List of methods to run for effects with their arguments and values. The methods are order dependant replecting how they are listed here. Example: ftLCustomEffects=""roundCorners();reflect(opacity=40,backgroundColor='black');""" />
		<cfargument name="convertImageToFormat" type="string" required="false" default="" hint6="Convert image to a specific format. Set value to image extension. Example: 'gif'. Leave blank for no conversion. Default=blank (no conversion)" />
		<cfargument name="bSetAntialiasing" type="boolean" required="true" default="true" hint="Use Antialiasing (better image, but slower performance)" />
		<cfargument name="interpolation" type="string" required="true" default="blackman" hint="set the interpolation level on the image compression" />
		<cfargument name="quality" type="string" required="false" default="0.8" hint="Quality of the JPEG destination file. Applies only to files with an extension of JPG or JPEG. Valid values are fractions that range from 0 through 1 (the lower the number, the lower the quality). Examples: 1, 0.9, 0.1. Default = 0.8" />
		<cfargument name="bUploadOnly" type="boolean" required="false" default="false" hint="The image file will be uploaded with no image optimization or changes." />
		<cfargument name="bSelfSourced" type="boolean" required="false" default="false" hint="The image file will be uploaded with no image optimization or changes." />
		<cfargument name="ResizeMethod" type="string" required="true" default="" hint="The y origin of the crop area. Options are center, topleft, topcenter, topright, left, right, bottomleft, bottomcenter, bottomright" />
		<cfargument name="watermark" type="string" required="false" default="" hint="The path relative to the webroot of an image to use as a watermark." />
		<cfargument name="watermarkTransparency" type="string" required="false" default="90" hint="The transparency to apply to the watermark." />
		
		<cfset var stResult = structNew() />
		<cfset var stImage = structnew() />
		<cfset var format = "" />
		
		<cfset stResult.bSuccess = true />
		<cfset stResult.message = "" />
		<cfset stResult.filename = "" />
		
		<cfsetting requesttimeout="120" />
		
		<cfif len(arguments.source) and not refindnocase("//res.cloudinary.com/",arguments.source)>
			<cfreturn super.GenerateImage(argumentCollection=arguments) />
		</cfif>
		
		<cfset stResult.filename = application.fc.lib.cloudinary.transform(file=arguments.source, transformation={
			width = arguments.width, 
			height = arguments.height, 
			crop = arguments.resizeMethod,
			format = arguments.convertImageToFormat
		}) />
		
		<cfreturn stResult />
	</cffunction>
	
	
	<cffunction name="uploadToCloudinary" access="public" output="false" returntype="string" hint="Uploads specified image to Cloudinary and returns Cloudinary image path">
		<cfargument name="file" type="string" required="true" />
		<cfargument name="publicID" type="string" required="false" default="#listfirst(listlast(arguments.file,'/'),'.')#_#application.fapi.getUUID()#" />
		<cfargument name="transformation" type="string" required="false" default="" />
		
		<cfset var uploadVia = application.fapi.getConfig("cloudinary", "uploadVia", "post") />
		
		<cfsetting requesttimeout="10000" />
		
		<cfswitch expression="#uploadVia#">
			<cfcase value="post">
				<cfreturn application.fc.lib.cloudinary.upload(file=arguments.file, publicID=arguments.publicID, transformation=arguments.transformation).urlWithSource />
			</cfcase>
			<cfcase value="fetch">
				<cfreturn application.fc.lib.cloudinary.fetch(file=arguments.file) />
			</cfcase>
			<cfcase value="auto">
				<cfreturn application.fc.lib.cloudinary.autoUpload(file=arguments.file) />
			</cfcase>
		</cfswitch>
		
		<cfreturn {} />
	</cffunction>
	
	
	<cffunction name="onDelete" access="public" output="false" returntype="void" hint="Called from setData when an object is deleted">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		
		<cfset var source = "" />
		
		<cfimport taglib="/farcry/core/tags/security" prefix="sec" />
		
		<cfif not len(arguments.stObject[arguments.stMetadata.name])>
			<cfreturn /><!--- No file attached --->
		</cfif>
		
		<cfif (not structkeyexists(arguments.stObject,"versionID") or not len(arguments.stObject.versionID))>
			<!--- source=xxx => original file for this image; _source=xxx => temporary variable used for dependant cuts --->
			<cfif refindnocase("//res.cloudinary.com/.*\?source=",arguments.stObject[arguments.stMetadata.name])>
				<cfset application.fc.lib.cloudinary.delete(file=arguments.stObject[arguments.stMetadata.name]) />
				
				<cfset source = application.fc.lib.cloudinary.getSource(arguments.stObject[arguments.stMetadata.name]) />
				
				<cfif application.fc.lib.cdn.ioFileExists(location="images",file=source)>
					<cfset application.fc.lib.cdn.ioDeleteFile(location="images",file=source) />
				</cfif>
			<cfelseif not refindnocase("//res.cloudinary.com/",arguments.stObject[arguments.stMetadata.name]) and application.fc.lib.cdn.ioFileExists(location="images",file="/#arguments.stObject[arguments.stMetadata.name]#")>
				<cfset application.fc.lib.cdn.ioDeleteFile(location="images",file="/#arguments.stObject[arguments.stMetadata.name]#") />
			</cfif>
		</cfif>
	</cffunction>
	
	<cffunction name="getFileLocation" access="public" output="false" returntype="struct" hint="Returns information used to access the file: type (stream | redirect), path (file system path | absolute URL), filename, mime type">
		<cfargument name="objectid" type="string" required="false" default="" hint="Object to retrieve" />
		<cfargument name="typename" type="string" required="false" default="" hint="Type of the object to retrieve" />
		<!--- OR --->
		<cfargument name="stObject" type="struct" required="false" hint="Provides the object" />
		
		<cfargument name="stMetadata" type="struct" required="false" hint="Property metadata" />
		<cfargument name="admin" type="boolean" required="false" default="false" />
		<cfargument name="bRetrieve" type="boolean" required="false" default="true" />

		<cfset var stResult = structnew() />
		
		<cfif not structkeyexists(arguments,"stObject")>
			<cfset argument.stObject = application.fapi.getContentObject(typename=arguments.typename,objectid=arguments.objectid) />
		</cfif>
		
		<!--- Throw an error if the field is empty --->
		<cfif NOT len(arguments.stObject[arguments.stMetadata.name])>
			<cfset stResult = structnew() />
			<cfset stResult.method = "none" />
			<cfset stResult.error = "No file defined" />
			<cfset stResult.path = "" />
			<cfreturn stResult />
		</cfif>
		
		<cfif arguments.admin and refindnocase("\?source=",arguments.stObject[arguments.stMetadata.name])>
			<cfset stResult = application.fc.lib.cdn.ioGetFileLocation(location="images",file=application.fc.lib.cloudinary.getSource(arguments.stObject[arguments.stMetadata.name])) />
		<cfelseif refindnocase("//res.cloudinary.com/",arguments.stObject[arguments.stMetadata.name])>
			<cfset stResult.path = rereplace(arguments.stObject[arguments.stMetadata.name],"\?_?source=[^&]+","") />
		<cfelse>
			<cfset stResult = application.fc.lib.cdn.ioGetFileLocation(location="images",file=arguments.stObject[arguments.stMetadata.name],admin=arguments.admin,bRetrieve=arguments.bRetrieve) />
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getFileExists" access="public" output="false" returntype="boolean" hint="Returns true if file is non-empty and exists">
		<cfargument name="file" type="string" required="true" />
		
		<cfif false and refindnocase("//res.cloudinary.com/.*\?_?source=",arguments.file)>
			<cfreturn application.fc.lib.cdn.ioFileExists(location='images',file=application.fc.lib.cloudinary.getSource(arguments.file)) />
		<cfelseif refindnocase("//res.cloudinary.com/",arguments.file)>
			<cfreturn true />
		<cfelseif len(arguments.file)>
			<cfreturn application.fc.lib.cdn.ioFileExists(location="images",file=arguments.file) />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="getImageInfo" access="public" output="false" returntype="struct" hint="Returns information about image">
		<cfargument name="file" type="string" required="true" />
		<cfargument name="admin" type="boolean" required="false" default="false" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stImage = structnew() />
		<cfset var stResult = structnew() />
		
		<cfif refindnocase("//res.cloudinary.com/.*\?source=",arguments.file) and application.fc.lib.cdn.ioFileExists(location='images',file=application.fc.lib.cloudinary.getSource(arguments.file))>
			
			<cfimage action="info" source="#application.fc.lib.cdn.ioReadFile(location='images',file=application.fc.lib.cloudinary.getSource(arguments.file),datatype='image')#" structName="stImage" />
			
			<cfset stResult["width"] = stImage.width />
			<cfset stResult["height"] = stImage.height />
			<cfset stResult["size"] = application.fc.lib.cdn.ioGetFileSize(location="images",file=application.fc.lib.cloudinary.getSource(arguments.file)) />
			
			<cfif arguments.admin>
				<cfset stResult["path"] = application.fc.lib.cdn.ioGetFileLocation(location="images",file=application.fc.lib.cloudinary.getSource(arguments.file)).path />
			<cfelse>
				<cfset stResult["path"] = rereplacenocase(arguments.file,"\?_?source=[^&]+","") />
			</cfif>
			
		<cfelseif refindnocase("//res.cloudinary.com/",arguments.file)>
			
			<cfhttp url="http:#rereplacenocase(arguments.file,'\?_?source=[^&]+','')#" getasbinary="yes" />

			<cfif left(cfhttp.statusCode, 3) eq "200">
				<cfimage action="info" source="#cfhttp.filecontent#" structName="stImage" />

				<cfset stResult["width"] = stImage.width />
				<cfset stResult["height"] = stImage.height />
				<cfset stResult["size"] = len(cfhttp.filecontent) />
				<cfset stResult["path"] = arguments.file />

			<cfelse>
				<cfset stResult["width"] = 0 />
				<cfset stResult["height"] = 0 />
				<cfset stResult["size"] = 0 />
				<cfset stResult["path"] = "" />
			</cfif>
			
		<cfelseif application.fc.lib.cdn.ioFileExists(location="images",file=arguments.file)>
		
			<cfimage action="info" source="#application.fc.lib.cdn.ioReadFile(location='images',file=arguments.file,datatype='image')#" structName="stImage" />
			
			<cfset stResult["width"] = stImage.width />
			<cfset stResult["height"] = stImage.height />
			<cfset stResult["size"] = application.fc.lib.cdn.ioGetFileSize(location="images",file=arguments.file) />
			<cfset stResult["path"] = application.fc.lib.cdn.ioGetFileLocation(location="images",file=arguments.file,admin=arguments.admin).path />
			
		<cfelse>
			
			<cfset stResult["width"] = 0 />
			<cfset stResult["height"] = 0 />
			<cfset stResult["size"] = 0 />
			<cfset stResult["path"] = "" />
			
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="duplicateFile" access="public" output="false" returntype="string" hint="For use with duplicateObject, copies the associated file and returns the new unique filename">
		<cfargument name="stObject" type="struct" required="false" hint="Provides the object" />
		<cfargument name="stMetadata" type="struct" required="false" hint="Property metadata" />
		
		<cfset var currentfilename = arguments.stObject[arguments.stMetadata.name] />
		<cfset var newfilename = "" />
		<cfset var currentlocation = "" />
		
		<cfif not len(currentfilename)>
			<cfreturn "" />
		</cfif>
		
		<cfif refindnocase("//res.cloudinary.com/.*\?source=",currentfilename)>
			
			<cfset newfilename = application.fc.lib.cdn.ioCopyFile(source_pathlocation="images",source_file=application.fc.lib.cloudinary.getSource(currentfilename),dest_location="images",nameconflict="makeunique",uniqueamong="images") />
			<cfreturn rereplacenocase(currentfilename,"\?source=[^&]+","") & "?source=#urlencodedformat(newfilename)#" />
			
		<cfelseif refindnocase("//res.cloudinary.com/",currentfilename)>
			
			<cfreturn rereplacenocase(currentfilename,"\?_?source=[^&]+","") />
		
		<cfelse>
		
			<cfset currentlocation = application.fc.lib.cdn.ioFindFile(locations="images",file=currentfilename) />
			
			<cfif isDefined("currentlocation") and not len(currentlocation)>
				<cfreturn "" />
			</cfif>
			
			<cfreturn application.fc.lib.cdn.ioCopyFile(source_pathlocation="images",source_file=currentfilename,dest_location="images",dest_file=newfilename,nameconflict="makeunique",uniqueamong="images") />
		
		</cfif>
	</cffunction>
	
	
</cfcomponent>