<cfcomponent extends="farcry.core.packages.formtools.arrayupload" output="false" persistent="false">
	
	<cffunction name="ajax" output="false" returntype="string" hint="Response to ajax requests for this formtool">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">
		
		<cfset var stResult = structnew() />
		<cfset var stFixed = structnew() />
		<cfset var stSource = structnew() />
		<cfset var stFile = structnew() />
		<cfset var stImage = structnew() />
		<cfset var resizeinfo = "" />
		<cfset var source = "" />
		<cfset var html = "" />
		<cfset var json = "" />
		<cfset var stJSON = structnew() />
	    <cfset var prefix = left(arguments.fieldname,len(arguments.fieldname)-len(arguments.stMetadata.name)) />
	    <cfset var stFP = structnew() />
	    <cfset var thisfield = "" />
	    <cfset var aItems = "" />
	    <cfset var stActions = structnew() />
	    <cfset var editprefix = "" />
	    <cfset var stNewObject = structnew() />
		
		<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
		<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
		
	    <cfif not listlen(arguments.stMetadata.ftJoin) eq 1>
			<cfthrow message="One related type must be specified in the ftJoin attribute" />
		</cfif>
	    <cfif not len(arguments.stMetadata.ftFileProperty)>
			<cfif arguments.stMetadata.ftJoin eq "dmImage">
				<cfset arguments.stMetadata.ftFileProperty = "sourceImage" />
			<cfelseif arguments.stMetadata.ftJoin eq "dmFile">
				<cfset arguments.stMetadata.ftFileProperty = "filename" />
			<cfelse>
				<cfthrow message="ftFileProperty is a required attribute" />
			</cfif>
		</cfif>
	    <cfif not len(arguments.stMetadata.ftAllowedFileExtensions) and isdefined("application.stCOAPI.#arguments.stMetadata.ftJoin#.stProps.#arguments.stMetadata.ftFileProperty#.metadata.ftAllowedFileExtensions") and len(application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftAllowedFileExtensions)>
			<cfset arguments.stMetadata.ftAllowedFileExtensions = application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftAllowedFileExtensions />
		<cfelseif not len(arguments.stMetadata.ftAllowedFileExtensions) and isdefined("application.stCOAPI.#arguments.stMetadata.ftJoin#.stProps.#arguments.stMetadata.ftFileProperty#.metadata.ftAllowedExtensions") and len(application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftAllowedExtensions)>
			<cfset arguments.stMetadata.ftAllowedFileExtensions = application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftAllowedExtensions />
		</cfif>
	    <cfif not len(arguments.stMetadata.ftSizeLimit) and isdefined("application.stCOAPI.#arguments.stMetadata.ftJoin#.stProps.#arguments.stMetadata.ftFileProperty#.metadata.ftSizeLimit") and len(application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftSizeLimit)>
			<cfset arguments.stMetadata.ftSizeLimit = application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftSizeLimit />
		<cfelse>
			<cfset arguments.stMetadata.ftSizeLimit = -1 />
		</cfif>
		
		<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
		
		<cfif structkeyexists(url,"check")>
			<cfreturn "[]" />
		</cfif>
		
		<cfif structkeyexists(url,"add")>
			<cfif not isdefined("form.items") or not len(form.items)>
				<cfreturn "" />
			</cfif>
			
			<!--- SETUP stActions --->
			<cfset stActions.ftAllowEdit = arguments.stMetadata.ftAllowEdit />
			<cfset stActions.ftRemoveType = arguments.stMetadata.ftRemoveType />
			
			<cfif arguments.stMetadata.ftRemoveType EQ "detach">
				<cfset stActions.ftRemoveType = "remove" />
			</cfif>
			
			<cfset aItems = arraynew(1) />
			<cfloop list="#form.items#" index="source">
				<cfset stResult = structnew() />
				<cfset stResult["objectid"] = source />
				<skin:view objectid="#source#" typename="#arguments.stMetadata.ftJoin#" webskin="#arguments.stMetadata.ftListWebskin#" alternateHTML="OBJECT NO LONGER EXISTS" r_html="html" />
				<cfset stResult["html"] = html />
				<cfset arrayappend(aItems,stResult) />
			</cfloop>
			
			<cfreturn serializeJSON(aItems) />
		</cfif>
		
		<cfif structkeyexists(url,"edit")><!--- Edit an array item --->
			<cfif not isdefined("form.item") or not len(form.item)>
				<cfreturn "No item specified" />
			</cfif>
			
			<cfset request.mode.ajax = true />
			<cfsavecontent variable="html"><cfoutput>
				<div style="border: 1px solid ##c8c8c8\9;background-color:##FFFFFF;padding:15px;-webkit-box-shadow: 0 0 8px rgba(128,128,128,0.75);-moz-box-shadow: 0 0 8px rgba(128,128,128,0.75);box-shadow: 0 0 8px rgba(128,128,128,0.75);">
					<ft:form>
						<ft:object objectid="#form.item#" lFields="#arguments.stMetadata.ftEditableProperties#" r_stPrefix="editprefix" />
						<ft:buttonPanel>
							<a href="##" class="closeModal">cancel</a>&nbsp;<ft:button value="Save" onclick="var base={};var props='#arguments.stMetadata.ftEditableProperties#'.split(',');for (var i in props) base[props[i]]='';$fc.arrayuploadformtool('#prefix#','#arguments.stMetadata.name#').saveItem('#form.item#',getValueData(base,'#editprefix#'));return false;" />
						</ft:buttonPanel>
					</ft:form>
				</div>
			</cfoutput></cfsavecontent>
			
			<cfreturn html />
		</cfif>
		
		<cfif structkeyexists(url,"update")><!--- Update an array item --->
			<cfif not isdefined("form._objectid") or not len(form._objectid)>
				<cfreturn "No data specified" />
			</cfif>
			
			<!--- SETUP stActions --->
			<cfset stActions.ftAllowEdit = arguments.stMetadata.ftAllowEdit />
			<cfset stActions.ftRemoveType = arguments.stMetadata.ftRemoveType />
			
			<cfif arguments.stMetadata.ftRemoveType EQ "detach">
				<cfset stActions.ftRemoveType = "remove" />
			</cfif>
			
			<cfset stSource = structnew() />
			<cfset stSource.objectid = form["_objectid"] />
			<cfset stSource.typename = arguments.stMetadata.ftJoin />
			<cfloop list="#arguments.stMetadata.ftEditableProperties#" index="thisfield">
				<cfset stSource[thisfield] = form["_#thisfield#"] />
			</cfloop>
			<cfset application.fapi.setData(stProperties=stSource) />
			
			<cfset stJSON = structnew() />
			<cfset stJSON["objectid"] = stSource.objectid />
			<skin:view objectid="#stSource.objectid#" typename="#arguments.stMetadata.ftJoin#" webskin="#arguments.stMetadata.ftListWebskin#" alternateHTML="OBJECT NO LONGER EXISTS" r_html="html" />
			<cfset stJSON["html"] = html />
			
			<cfreturn serializeJSON(stJSON) />
		</cfif>
		
		<cfif structkeyexists(url,"delete")>
			<cfif not isdefined("form.items") or not len(form.items)>
				<cfreturn "[]" />
			</cfif>
			
			<cfset aItems = listtoarray(form.items) />
			<cfif arguments.stMetadata.ftRemoveType eq "delete">
				<cfset source = application.fapi.getContentType(arguments.stMetadata.ftJoin) />
				<cfloop from="1" to="#arraylen(aItems)#" index="i">
					<cfset source.deleteData(aItems[i]) />
				</cfloop>
			</cfif>
			
			<cfreturn serializeJSON(aItems) />
		</cfif>
		
		<cfif structkeyexists(url,"upload")><!--- Edit an array item --->
			<cfif application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftType eq "file">
				
				<cfset stResult = handleFilePost(
					objectid=arguments.stObject.objectid,
					uploadfield="#arguments.stMetadata.name#UPLOAD",
					destination=application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftDestination,
					location="publicfiles",
					allowedExtensions=arguments.stMetadata.ftAllowedFileExtensions,
					stFieldPost=arguments.stFieldPost.stSupporting,
					sizeLimit=arguments.stMetadata.ftSizeLimit) />
				<cfset stResult.location = "publicfiles" />
				
			<cfelse><!--- File property is an image formtool --->
				
				<cfset stResult = handleFilePost(
					objectid=arguments.stObject.objectid,
					uploadfield="#arguments.stMetadata.name#UPLOAD",
					destination=application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftDestination,
					location="images",
					allowedExtensions=arguments.stMetadata.ftAllowedFileExtensions,
					stFieldPost=arguments.stFieldPost.stSupporting,
					sizeLimit=arguments.stMetadata.ftSizeLimit) />
				<cfset stResult.location = "images" />
					
			</cfif>
			
			<cfif isdefined("stResult.stError.message") and len(stResult.stError.message)>
				<cfset stJSON = structnew() />
				<cfset stJSON["error"] = stResult.stError.message />
				<cfset stJSON["value"] = stResult.value />
				<cfreturn serializeJSON(stJSON) />
			</cfif>
			
			<cfif isdefined("stResult.bSuccess") and stResult.bSuccess and isdefined("stResult.value") and len(stResult.value)>
				
				<cfif application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftType eq "file">
					
					<cfset stFile = application.fc.lib.cdn.ioGetFileLocation(location=stResult.location,file=stResult.value) />
					
					<cfset stNewObject = application.fapi.getNewContentObject(typename=arguments.stMetadata.ftJoin) />
					<cfset stNewObject.label = listfirst(listlast(stResult.value,"/"),".") />
					<cfset stNewObject[arguments.stMetadata.ftFileProperty] = stResult.value />
					<cfset application.fapi.setData(stProperties=stNewObject) />
					
					<cfif structkeyexists(application.formtools.file.oFactory,"onFileChange")>
						<cfset application.formtools.file.oFactory.onFileChange(typename=arguments.stMetadata.ftJoin,objectid=stNewObject.objectid,stMetadata=application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata,value=stResult.value) />
					</cfif>
					
					<cfset stJSON = structnew() />
					<cfset stJSON["objectid"] = stNewObject.objectid />
					<cfset stJSON["value"] = stResult.value />
					<cfset stJSON["filename"] = listlast(stResult.value,"/") />
					<cfset stJSON["fullpath"] = stFile.path />
					<cfset stJSON["size"] = round(application.fc.lib.cdn.ioGetFileSize(location=stResult.location,file=stResult.value)/1024) />
					<skin:view objectid="#stNewObject.objectid#" typename="#arguments.stMetadata.ftJoin#" webskin="#arguments.stMetadata.ftListWebskin#" bIgnoreSecurity="true" r_html="html" alternateHTML="OBJECT NO LONGER EXISTS" />
					<cfset stJSON["html"] = html />
					
				<cfelse><!--- File property is an image formtool --->
					
					<cfif not structkeyexists(arguments.stFieldPost.stSupporting,"ResizeMethod") or not isnumeric(arguments.stFieldPost.stSupporting.ResizeMethod)>
						<cfset arguments.stFieldPost.stSupporting.ResizeMethod = application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftAutoGenerateType />
					</cfif>
					<cfif not structkeyexists(arguments.stFieldPost.stSupporting,"Quality") or not isnumeric(arguments.stFieldPost.stSupporting.Quality)>
						<cfset arguments.stFieldPost.stSupporting.Quality = application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata.ftQuality />
					</cfif>
					
					<cftry>
						<cfset stJSON = structnew() />
						<cfset stFixed = application.formtools.image.oFactory.fixImage("#stResult.value#",application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata,arguments.stFieldPost.stSupporting.ResizeMethod,arguments.stFieldPost.stSupporting.Quality) />
						
						<cfset stNewObject = application.fapi.getNewContentObject(typename=arguments.stMetadata.ftJoin) />
						<cfset stNewObject.label = listfirst(listlast(stResult.value,"/"),".") />
						<cfif structkeyexists(application.stCOAPI[arguments.stMetadata.ftJoin].stProps,"title")>
							<cfset stNewObject.title = stNewObject.label />
						</cfif>
						<cfif structkeyexists(application.stCOAPI[arguments.stMetadata.ftJoin].stProps,"name")>
							<cfset stNewObject.name = stNewObject.label />
						</cfif>
						<cfset stNewObject[arguments.stMetadata.ftFileProperty] = stResult.value />
						<cfloop collection="#application.stCOAPI[arguments.stMetadata.ftJoin].stProps#" item="thisfield">
							<cfif isdefined("application.stCOAPI.#arguments.stMetadata.ftJoin#.stProps.#thisfield#.metadata.ftType") 
								and application.stCOAPI[arguments.stMetadata.ftJoin].stProps[thisfield].metadata.ftType eq "image"
								and isdefined("application.stCOAPI.#arguments.stMetadata.ftJoin#.stProps.#thisfield#.metadata.ftSourceField")
								and listfirst(application.stCOAPI[arguments.stMetadata.ftJoin].stProps[thisfield].metadata.ftSourceField,":") eq arguments.stMetadata.ftFileProperty>
								
								<cfset stFP[thisfield] = structnew() />
								
							</cfif>
						</cfloop>
						<cfset stNewObject = application.formtools.image.oFactory.ImageAutoGenerateBeforeSave(typename=stNewObject.typename,stProperties=stNewObject,stFields=application.stCOAPI[arguments.stMetadata.ftJoin].stProps,stFormPost=stFP) />
						<cfset application.fapi.setData(stProperties=stNewObject) />
						
						<cfif structkeyexists(application.formtools.image.oFactory,"onFileChange")>
							<cfset application.formtools.image.oFactory.onFileChange(typename=arguments.stMetadata.ftJoin,objectid=stNewObject.objectid,stMetadata=application.stCOAPI[arguments.stMetadata.ftJoin].stProps[arguments.stMetadata.ftFileProperty].metadata,value=stResult.value) />
						</cfif>
						
						<cfset stFile = application.fc.lib.cdn.ioGetFileLocation(location=stResult.location,file=application.formtools.image.oFactory.getCloudinarySource(stResult.value)) />

						<cfimage action="info" source="#application.fc.lib.cdn.ioReadFile(location=stResult.location,file=application.formtools.image.oFactory.getCloudinarySource(stResult.value),datatype='image')#" structName="stImage" />
						<cfset stJSON["objectid"] = stNewObject.objectid />
						<cfset stJSON["value"] = stResult.value />
						<cfset stJSON["filename"] = listlast(stResult.value,'/') />
						<cfset stJSON["fullpath"] = stFile.path />
						<cfset stJSON["size"] = round(application.fc.lib.cdn.ioGetFileSize(location=stResult.location,file=application.formtools.image.oFactory.getCloudinarySource(stResult.value))/1024) />
						<skin:view objectid="#stNewObject.objectid#" typename="#arguments.stMetadata.ftJoin#" webskin="#arguments.stMetadata.ftListWebskin#" bIgnoreSecurity="true" r_html="html" alternateHTML="OBJECT NO LONGER EXISTS" />
						<cfset stJSON["html"] = html />
						
						<cfcatch>
							<cfset stJSON["error"] = cfcatch.message />
							<cfset stJSON["value"] = "" />
						</cfcatch>
					</cftry>
					
				</cfif>

				<cfreturn serializeJSON(stJSON) />
				
			</cfif>
		</cfif>
		
		<cfreturn "{}" />
	</cffunction>

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
<cflog file="shooting-debug" text="#serializeJSON(stResult)#" />		
		<cfreturn stResult />
	</cffunction>

</cfcomponent>