<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Cloudinary migration --->

<cfset filesPerTask = 20 />
<cfset progressFile = application.path.secureFilePath & "/cloudinarymigration.txt" />
<cfset aSkipFiles = arraynew(1) />
<cfset aSkipTypes = arraynew(1) />

<!--- if the task was executed from the webtop, the url variables won't be set --->
<cfloop list="#stObj.parameters#" index="thisparam" delimiters="&">
	<cfif not structkeyexists(url,listfirst(thisparam,":"))>
		<cfset url[listfirst(thisparam,":")] = listlast(thisparam,":") />
	</cfif>
</cfloop>

<!--- load migration information --->
<cfif fileexists(progressFile)>
	<cffile action="read" file="#progressFile#" variable="progressData" />
	
	<cfloop list="#progressData#" index="progressLine" delimiters="#chr(10)##chr(13)#">
		<cfset progressLine = trim(progressLine) />
		
		<cfif refindnocase("^Finished type:",progressLine)>
			<cfset arrayappend(aSkipTypes,listlast(progressLine,":")) />
		<cfelseif refindnocase("^Missing file:",progressLine)>
			<cfset arrayappend(aSkipFiles,listlast(progressLine,":")) />
		</cfif>
	</cfloop>
</cfif>

<!--- find images to upload --->
<cfset qWrong = querynew("typename,typelabel,property,seq,objectid,label,filename,issource","varchar,varchar,varchar,integer,varchar,varchar,varchar,bit") />

<cfloop collection="#application.stCOAPI#" item="thistype">
	<cfif qWrong.recordcount lt filesPerTask and not arrayfind(aSkipTypes,thistype) and listcontains("type,rule",application.stCOAPI[thistype].class)>
		<cfset processType = false />
		
		<cfloop collection="#application.stCOAPI[thistype].stProps#" item="thisprop">
			<cfif qWrong.recordcount lt filesPerTask and isdefined("application.stCOAPI.#thistype#.stProps.#thisprop#.metadata.ftType") and application.stCOAPI[thistype].stProps[thisprop].metadata.ftType eq "image">
				<cfset o = application.fapi.getContentType(typename=thistype) />
				<cfquery datasource="#application.dsn#" name="q">
					select		objectid,label,#thisprop#
					from		#application.dbowner##thistype#
					where		#thisprop#<>'' and #thisprop# not like <cfqueryparam cfsqltype="cf_sql_varchar" value="//res.cloudinary.com/%">
				</cfquery>
				
				<cfloop query="q">
					<cfif qWrong.recordcount lt filesPerTask and not arrayfind(aSkipFiles,q[thisprop][q.currentrow])>
						<cfset processType = true />
						
						<cfset queryaddrow(qWrong) />
						<cfset querysetcell(qWrong,"typename",thistype) />
						<cfset querysetcell(qWrong,"typelabel",application.stCOAPI[thistype].displayname) />
						<cfset querysetcell(qWrong,"property",thisprop) />
						<cfset querysetcell(qWrong,"seq",application.stCOAPI[thistype].stProps[thisprop].metadata.ftSeq) />
						<cfset querysetcell(qWrong,"objectid",q.objectid) />
						<cfset querysetcell(qWrong,"label",q.label) />
						<cfset querysetcell(qWrong,"filename",listlast(q[thisprop][q.currentrow],"\/")) />
						<cfset querysetcell(qWrong,"issource",not structkeyexists(application.stCOAPI[thistype].stProps[thisprop].metadata,"ftSourceField") or not len(application.stCOAPI[thistype].stProps[thisprop].metadata.ftSourceField))>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
		
		<cfif not processType>
			<cffile action="append" file="#progressFile#" addnewline="true" output="Finished type:#thistype#" />
			<cfoutput>Finished type: #thistype#<br></cfoutput>
		</cfif>
	</cfif>
</cfloop>

<!--- process files --->
<cfloop query="qWrong">
	<cfset stObject = application.fapi.getContentObject(typename=qWrong.typename,objectid=qWrong.objectid) />

	<cfif not findnocase("//res.cloudinary.com/",stObject[qWrong.property])>
		<cfif application.fc.lib.cdn.ioFileExists(location="images",file=stObject[qWrong.property])>
			<cfset stFile = application.formtools.image.oFactory.uploadToCloudinary(file=stObject[qWrong.property]) />
			<cfset stObject[qWrong.property] = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(stObject[qWrong.property])#" />
			
			<cfset application.fapi.setData(stProperties=stObject) />
			
			<cffile action="append" file="#progressFile#" addnewline="true" output="File migrated:#stObject[qWrong.property]#" />
			<cfoutput>File migrated: <a href="#stObject[qWrong.property]#">#stObject[qWrong.property]#</a><br></cfoutput>
		<cfelse>
			<cffile action="append" file="#progressFile#" addnewline="true" output="Missing file:#stObject[qWrong.property]#" />
			<cfoutput>Missing file: #stObject[qWrong.property]#<br></cfoutput>
		</cfif>
	<cfelse>
		<cffile action="append" file="#progressFile#" addnewline="true" output="Already migrated:#stObject[qWrong.property]#" />
		<cfoutput>Already migrated: <a href="#stObject[qWrong.property]#">#stObject[qWrong.property]#</a><br></cfoutput>
	</cfif>
</cfloop>

<cfif qWrong.recordcount>
	<cfset newTime = dateadd("n",1,now()) />
	
	<!--- add/update task --->
	<cfschedule 
		action="UPDATE" 
		task = "#application.applicationName#_#stObj.title#"
		operation = "HTTPRequest"
		url = "http://#cgi.HTTP_HOST##application.url.conjurer#?objectid=#stObj.objectid#&#stObj.parameters#"
		interval = "Once"
		startdate = "#dateFormat(newTime,'dd/mmm/yyyy')#"
		starttime = "#timeFormat(newTime,'hh:mm tt')#"
		requesttimeout = "#stObj.timeout#">
	
	<cffile action="append" file="#progressFile#" addnewline="true" output="Task rescheduled" />
	<cfoutput>Task rescheduled<br></cfoutput>
<cfelse>
	<cffile action="append" file="#progressFile#" addnewline="true" output="Migration complete" />
	
	<cftry>
		<cfschedule 
			action="DELETE" 
			task = "#application.applicationName#_#stObj.title#">
		
		<cfcatch></cfcatch>
	</cftry>
	<cffile action="append" file="#progressFile#" addnewline="true" output="Task deleted" />
	<cfoutput>Task deleted<br></cfoutput>
	
	<cfif structkeyexists(url,"notification")>
		<cfmail to="#url.notification#" from="alerts@daemon.com.au" subject="Cloudinary migration complete for #application.applicationname#">
			<cfoutput>Migration log attached</cfoutput>
			<cfmailparam file="#progressFile#" type="text/plain"> 
		</cfmail>
		
		<cfoutput>Notification sent to #url.notification#<br></cfoutput>
	</cfif>
</cfif>

<cfsetting enablecfoutputonly="false" />