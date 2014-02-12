<cfcomponent extends="farcry.core.packages.formtools.image" output="false" persistent="false">
	
	<cfproperty name="ftShowMetadata" type="boolean" default="false" hint="If this is set to false, the file size and dimensions of the current image are not displayed to the user" />
	<cfproperty name="dbPrecision" type="string" default="500" />
	
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
			<cfset sourceFile = getCloudinarySource(arguments.existingfile) />
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
						<cfset stFile = uploadToCloudinary(file=uploadFileName,publicID=getCloudinaryID(arguments.existingfile)) />
					<cfelse>
						<cfset stFile = uploadToCloudinary(file=uploadFileName) />
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
					<cfset stFile = uploadToCloudinary(uploadFileName) />
					<cfset uploadFileName = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(uploadFileName)#" />
					
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
			<cfset sourceFile = getCloudinarySource(arguments.existingfile) />
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
					<cfset application.fc.lib.cdn.ioMoveFile(source_localpath=arguments.localpath,dest_location="images",dest_file=arguments.destination & "/" & uploadFilenName) />
					
					<!--- Copy to cloudinary --->
					<cfset uploadFileName = "#arguments.destination#/#uploadFileName#" />
					<cfif refindnocase("//res.cloudinary.com/",arguments.existingfile)>
						<cfset stFile = uploadtocloudinary(uploadFileName,getCloudinaryID(arguments.existingFile)) />
					<cfelse>
						<cfset stFile = uploadtocloudinary(uploadFileName) />
					</cfif>
					<cfset uploadFileName = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(uploadFileName)#" />
					
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
					<cfset uploadFileName = application.fc.lib.cdn.ioMoveFile(source_localpath=arguments.localpath,dest_location="images",dest_file=arguments.destination & "/" & getFileFromPath(arguments.localfile),nameconflict="makeunique") />
					
					<cfset stFile = uploadtocloudinary(uploadFileName) />
					<cfset uploadFileName = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(uploadFileName)#" />
					
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
		<cfif len(sourcefilename) and not refindnocase("//res.cloudinary.com/",sourcefilename)>
			<cfthrow message="Source has not been migrated to Cloudinary" />
		</cfif>
		
		<!--- source=xxx => original file for this image; _source=xxx => temporary variable used for dependant cuts --->
		<cfif refind("\?(source|_source)=",sourcefilename)>
			<cfreturn passed(rereplace(sourcefilename,"\?_?source=[^&]+","") & "?_source=" & getCloudinarySource(sourcefilename)) />
		<cfelse>
			<cfreturn passed(sourcefilename) />
		</cfif>
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
		
		<cfset format = createCloudinaryTransformation(arguments.width,arguments.height,arguments.resizeMethod) />
		
		<!--- Modify extension to convert image format --->
		<cfif not len(arguments.convertImageToFormat)>
			<cfset arguments.convertImageToFormat = listlast(listfirst(arguments.source,"?"),".") />
		</cfif>
		
		<cfif refind("\?source=",arguments.source)>
			<cfset stResult.filename = "//res.cloudinary.com/#application.config.cloudinary.cloudName#/image/upload/#format#/#getCloudinaryID(arguments.source)#.#arguments.convertImageToFormat#?source=#getCloudinarySource(arguments.source)#" />
		<cfelse>
			<cfset stResult.filename = "//res.cloudinary.com/#application.config.cloudinary.cloudName#/image/upload/#format#/#getCloudinaryID(arguments.source)#.#arguments.convertImageToFormat#" />
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	
	<cffunction name="createCloudinaryTransformation" access="public" output="false" returntype="string" hint="Returns a Cloudinary transformation string">
		<cfargument name="width" type="numeric" required="false" default="0" hint="The maximum width of the new image." />
		<cfargument name="height" type="numeric" required="false" default="0" hint="The maximum height of the new image." />
		<cfargument name="ResizeMethod" type="string" required="true" default="" hint="The y origin of the crop area. Options are center, topleft, topcenter, topright, left, right, bottomleft, bottomcenter, bottomright" />
		
		<cfset var format = "" />
		<cfset var pixels = "" />
		
		<cfswitch expression="#arguments.ResizeMethod#">
		
			<cfcase value="ForceSize">
				<!--- Simply force the resize of the image into the width/height provided --->
				<cfset format = listappend(format,"c_scale") />
				
				<cfif arguments.width gt 0>
					<cfset format = listappend(format,"w_#arguments.width#") />
				</cfif>
				
				<cfif arguments.height gt 0>
					<cfset format = listappend(format,"h_#arguments.height#") />
				</cfif>
			</cfcase>
			
			<cfcase value="FitInside">
				<cfset format = listappend(format,"c_fit") />
				
				<cfif arguments.width gt 0>
					<cfset format = listappend(format,"w_#arguments.width#") />
				</cfif>
				
				<cfif arguments.height gt 0>
					<cfset format = listappend(format,"h_#arguments.height#") />
				</cfif>
			</cfcase>
			
			<cfcase value="CropToFit">
				<cfset format = listappend(format,"c_fill") />
				
				<cfif arguments.width gt 0>
					<cfset format = listappend(format,"w_#arguments.width#") />
				</cfif>
				
				<cfif arguments.height gt 0>
					<cfset format = listappend(format,"h_#arguments.height#") />
				</cfif>
			</cfcase>
	
			<cfcase value="Pad">
				<cfset format = listappend(format,"c_pad") />
				
				<cfif arguments.width gt 0>
					<cfset format = listappend(format,"w_#arguments.width#") />
				</cfif>
				
				<cfif arguments.height gt 0>
					<cfset format = listappend(format,"h_#arguments.height#") />
				</cfif>
			</cfcase>
			
			<cfcase value="center,topleft,topcenter,topright,left,right,bottomleft,bottomcenter,bottomright">
				<cfset format = listappend(format,"c_fill") />
				
				<cfif arguments.width gt 0>
					<cfset format = listappend(format,"w_#arguments.width#") />
				</cfif>
				
				<cfif arguments.height gt 0>
					<cfset format = listappend(format,"h_#arguments.height#") />
				</cfif>
				
				<cfswitch expression="#arguments.resizeMethod#">
					<cfcase value="center">
						<cfset format = listappend(format,"g_faces:center") />
					</cfcase>
					<cfcase value="topleft">
						<cfset format = listappend(format,"g_north_west") />
					</cfcase>
					<cfcase value="topcenter">
						<cfset format = listappend(format,"g_north") />
					</cfcase>
					<cfcase value="topright">
						<cfset format = listappend(format,"g_north_east") />
					</cfcase>
					<cfcase value="left">
						<cfset format = listappend(format,"g_west") />
					</cfcase>
					<cfcase value="right">
						<cfset format = listappend(format,"g_east") />
					</cfcase>
					<cfcase value="bottomleft">
						<cfset format = listappend(format,"g_south_west") />
					</cfcase>
					<cfcase value="bottomcenter">
						<cfset format = listappend(format,"g_south") />
					</cfcase>
					<cfcase value="bottomright">
						<cfset format = listappend(format,"g_south_east") />
					</cfcase>
				</cfswitch>
			</cfcase> 
			
			<cfdefaultcase>
				<cfif refind("^\d+,\d+-\d+,\d+$",arguments.resizeMethod)>
					<cfset pixels = listtoarray(arguments.resizeMethod,",-") />
					
					<!--- crop to selected section --->
					<cfset format = listappend(format,"x_#pixels[1]#,y_#pixels[2]#,w_#pixels[3]-pixels[1]#,h_#pixels[4]-pixels[2]#,c_crop") />
					
					<!--- resize selected section to required size --->
					<cfset format = format & "/c_fit" />
					
					<cfif arguments.Width gt 0>
						<cfset format = listappend(format,"w_#arguments.width#") />
					</cfif>
					
					<cfif arguments.Height gt 0>
						<cfset format = listappend(format,"h_#arguments.height#") />
					</cfif>
				</cfif>
			</cfdefaultcase>
			
		</cfswitch>
		
		<cfreturn format />
	</cffunction>
	
	<cffunction name="uploadToCloudinary" access="public" output="false" returntype="struct" hint="Uploads specified image to Cloudinary and returns Cloudinary image path">
		<cfargument name="file" type="string" required="true" />
		<cfargument name="publicID" type="string" required="false" default="#listfirst(listlast(arguments.file,'/'),'.')#_#application.fapi.getUUID()#" />
		<cfargument name="transformation" type="string" required="false" default="" />
		
		<!--- GENERATE SIGNATURE --->
		<cfset var sigTimestamp = DateDiff('s', CreateDate(1970,1,1), now()) />
		<cfset var sigSignature = "" />
		<cfset var stResult = structnew() />
		<cfset var cfhttp = structnew() />
		
		<cfsetting requesttimeout="10000" />
		
		<cfif not isdefined("application.config.cloudinary.cloudName") or not len(application.config.cloudinary.cloudName)
			and not isdefined("application.config.cloudinary.apiKey") or not len(application.config.cloudinary.apiKey)
			and not isdefined("application.config.cloudinary.apiSecret") or not len(application.config.cloudinary.apiSecret)>
			
			<cfthrow message="Cloudinary has not been configured - add the Cloud Name, API Key and API Secret" />
			
		</cfif>
		
		<cfset sigSignature = lcase( hash( "public_id=#arguments.publicID#&timestamp=#sigTimestamp##application.config.cloudinary.apiSecret#" ,"SHA" ) ) />
		
		<!--- UPLOAD TO CLOUDINARY --->
		<cfhttp url="https://api.cloudinary.com/v1_1/#application.config.cloudinary.cloudName#/image/upload" method="POST" multipart="true" >
			<cfhttpparam type="formfield" name="api_key" value="#application.config.cloudinary.apiKey#">
			<cfhttpparam type="formfield" name="public_id" value="#arguments.publicID#">
			<cfhttpparam type="formfield" name="timestamp" value="#sigTimestamp#">
			<cfhttpparam type="formfield" name="signature" value="#trim(sigSignature)#">
			<cfif len(arguments.transformation)>
				<cfhttpparam type="formfield" name="transformation" value="#arguments.transformation#" />
			</cfif>
			<cfhttpparam type="file" name="file" file="#application.fc.lib.cdn.ioReadFile(location='images',file=arguments.file,datatype='image').source#" />
		</cfhttp>
		
		<cfif isjson(cfhttp.filecontent)>
			<cfset stResult = deserializejson(cfhttp.filecontent) />
		</cfif>
		
		<cfif cfhttp.StatusCode neq "200 Ok">
			<cfif structkeyexists(stResult,"error")>
				<!--- Cloudinary threw error, returned information --->
				<cfthrow message="Error uploading to Cloudinary: #stResult.error.message#" detail="#cfhttp.filecontent.toString()#" />
			<cfelse>
				<!--- Cloudinary threw error, no information --->
				<cfthrow message="Error uploading to Cloudinary" detail="#cfhttp.filecontent.toString()#" />
			</cfif>
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="deleteFromCloudinary" access="public" output="false" returntype="struct" hint="Removes specified image from Cloudinary">
		<cfargument name="file" type="string" required="true" />
		
		<!--- GENERATE SIGNATURE --->
		<cfset var sigTimestamp = DateDiff('s', CreateDate(1970,1,1), now()) />
		<cfset var sigSignature = "" />
		<cfset var stResult = structnew() />
		<cfset var cfhttp = structnew() />
		<cfset var publicID = "" />
		
		<cfif not isdefined("application.config.cloudinary.cloudName") or not len(application.config.cloudinary.cloudName)
			and not isdefined("application.config.cloudinary.apiKey") or not len(application.config.cloudinary.apiKey)
			and not isdefined("application.config.cloudinary.apiSecret") or not len(application.config.cloudinary.apiSecret)>
			
			<cfthrow message="Cloudinary has not been configured - add the Cloud Name, API Key and API Secret" />
			
		</cfif>
		
		<cfset publicID = getCloudinaryID(arguments.file) />
		<cfset sigSignature = lcase( hash( "public_id=#publicID#&timestamp=#sigTimestamp##application.config.cloudinary.apiSecret#" ,"SHA" ) ) />
		
		<!--- DELETE FROM CLOUDINARY --->
		<cfhttp url="https://api.cloudinary.com/v1_1/#application.config.cloudinary.cloudName#/resources/image/upload?public_ids=#publicID#" method="DELETE" username="#application.config.cloudinary.apiKey#" password="#application.config.cloudinary.apiSecret#"></cfhttp>
		
		<cfif isjson(cfhttp.filecontent)>
			<cfset stResult = deserializejson(cfhttp.filecontent) />
		</cfif>
		
		<cfif cfhttp.StatusCode neq "200 Ok">
			<cfif structkeyexists(stResult,"error")>
				<!--- Cloudinary threw error, returned information --->
				<cfthrow message="Error deleting from Cloudinary: #stResult.error.message#" detail="#cfhttp.filecontent.toString()#" />
			<cfelse>
				<!--- Cloudinary threw error, no information --->
				<cfthrow message="Error deleting from Cloudinary" detail="#cfhttp.filecontent.toString()#" />
			</cfif>
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getCloudinaryID" access="public" output="false" returntype="string" hint="Returns an image public ID based on it's URL">
		<cfargument name="file" type="string" required="true" />
		
		<cfreturn urldecode(listfirst(listlast(listfirst(arguments.file,"?"),"/"),".")) />
	</cffunction>
	
	<cffunction name="getCloudinarySource" access="public" output="false" returntype="string" hint="Returns the source embedded in a Cloudinary image path">
		<cfargument name="file" type="string" required="true" />
		
		<cfif refindnocase("\?_?source=",arguments.file)>
			<cfreturn urldecode(rereplacenocase(arguments.file,".*\?_?source=([^&]+).*","\1")) />
		<cfelse>
			<cfreturn "" />
		</cfif>
	</cffunction>
	
	<cffunction name="getCloudinaryInfo" access="public" output="false" returntype="struct" hint="Returns information from Cloudinary about image">
		<cfargument name="file" type="string" required="true" />
		
		<cfset var cfhttp = structnew() />
		<cfset var publicID = getCloudinaryID(arguments.file) />
		<cfset var stResult = structnew() />
		
		<cfif not refindnocase("//res.cloudinary.com/",arguments.file)>
			<cfthrow message="Source has not been migrated to Cloudinary" />
		</cfif>
		
		<cfhttp url="https://api.cloudinary.com/v1_1/#application.config.cloudinary.cloudName#/resources/image/upload/#publicID#" username="#application.config.cloudinary.apiKey#" password="#application.config.cloudinary.apiSecret#"></cfhttp>
		
		<cfif isjson(cfhttp.filecontent)>
			<cfset stResult = deserializejson(cfhttp.filecontent) />
		</cfif>
		
		<cfif cfhttp.StatusCode neq "200 Ok">
			<cfif structkeyexists(stResult,"error")>
				<!--- Cloudinary threw error, returned information --->
				<cfthrow message="Error querying Cloudinary: #stResult.error.message#" detail="#cfhttp.filecontent.toString()#" />
			<cfelse>
				<!--- Cloudinary threw error, no information --->
				<cfthrow message="Error querying Cloudinary" detail="#cfhttp.filecontent.toString()#" />
			</cfif>
		</cfif>
		
		<cfreturn stResult />
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
				<cfset deleteFromCloudinary(file=arguments.stObject[arguments.stMetadata.name]) />
				
				<cfset source = getCloudinarySource(arguments.stObject[arguments.stMetadata.name]) />
				
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
		
		<cfif arguments.admin and refindnocase("\?_?source=",arguments.stObject[arguments.stMetadata.name])>
			<cfset stResult = application.fc.lib.cdn.ioGetFileLocation(location="images",file=getCloudinarySource(arguments.stObject[arguments.stMetadata.name])) />
		<cfelseif refindnocase("//res.cloudinary.com/",arguments.stObject[arguments.stMetadata.name])>
			<cfset stResult.path = rereplace(arguments.stObject[arguments.stMetadata.name],"\?_?source=[^&]+","") />
		<cfelse>
			<cfset stResult = application.fc.lib.cdn.ioGetFileLocation(location="images",file=arguments.stObject[arguments.stMetadata.name],admin=arguments.admin) />
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getFileExists" access="public" output="false" returntype="boolean" hint="Returns true if file is non-empty and exists">
		<cfargument name="file" type="string" required="true" />
		
		<cfif false and refindnocase("//res.cloudinary.com/.*\?_?source=",arguments.file)>
			<cfreturn application.fc.lib.cdn.ioFileExists(location='images',file=getCloudinarySource(arguments.file)) />
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
		
		<cfif refindnocase("//res.cloudinary.com/.*\?_?source=",arguments.file) and application.fc.lib.cdn.ioFileExists(location='images',file=getCloudinarySource(arguments.file))>
			
			<cfimage action="info" source="#application.fc.lib.cdn.ioReadFile(location='images',file=getCloudinarySource(arguments.file),datatype='image')#" structName="stImage" />
			
			<cfset stResult["width"] = stImage.width />
			<cfset stResult["height"] = stImage.height />
			<cfset stResult["size"] = application.fc.lib.cdn.ioGetFileSize(location="images",file=getCloudinarySource(arguments.file)) />
			
			<cfif arguments.admin>
				<cfset stResult["path"] = application.fc.lib.cdn.ioGetFileLocation(location="images",file=getCloudinarySource(arguments.file)).path />
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
			
			<cfset newfilename = application.fc.lib.cdn.ioCopyFile(source_pathlocation="images",source_file=getCloudinarySource(currentfilename),dest_location="images",nameconflict="makeunique",uniqueamong="images") />
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