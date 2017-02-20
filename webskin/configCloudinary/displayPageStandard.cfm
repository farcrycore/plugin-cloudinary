<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Cloudinary Migrator --->
<!--- @@fuAlias: migrator --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfset REQUEST.mode.BADMIN = FALSE />
<skin:view typename="configcloudinary"  webskin="displayTypeBody" />

<cfsetting enablecfoutputonly="true" />