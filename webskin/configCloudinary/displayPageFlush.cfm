<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Cloudinary Migrator - Flush ObjectBroker --->
<!--- @@fuAlias: flush --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<cftry>
	<cfset REQUEST.mode.BADMIN = FALSE>
	<cfoutput><h1>flush ObjectBroker Cache</h1></cfoutput>
	
	
	
	<cfif NOT StructKeyExists(URL, "typename")>
		<cfdump var="#URL#" label="url">
		<cfabort showerror="typename not passed in [/cloudinary/flush/typename/dmImage/objectid/1FA49D74-C58F-40B5-BF124A4B915B4AA5]">
	</cfif>
	
	<cfif NOT StructKeyExists(URL, "objectid")>
		<cfdump var="#URL#" label="url">
		<cfabort showerror="objectid not passed in [/cloudinary/flush/typename/dmImage/objectid/1FA49D74-C58F-40B5-BF124A4B915B4AA5]">
	</cfif>
	
<!--- 	<cfset stObj = application.fapi.getContentObject(URL.objectid, URL.typename) />
	<cfdump var="#stObj#" label="before"> --->
	
	<cfset application.fc.lib.objectbroker.RemoveFromObjectBroker(lobjectids=URL.objectid, typename=URL.typename)>
	
<!--- 	<cfset stObj = application.fapi.getContentObject(URL.objectid, URL.typename) />
	<cfdump var="#stObj#" label="after"> --->
	
	<cfoutput><p>done</p></cfoutput>
	
	<cfcatch>
		<cfdump var="#cfcatch#" label="error">
	</cfcatch>
</cftry>

<cfsetting enablecfoutputonly="false" />