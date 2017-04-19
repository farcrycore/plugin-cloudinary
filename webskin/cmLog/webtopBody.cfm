<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Cloudinary Migrator Log --->

<cfimport taglib="/farcry/core/tags/formtools" prefix="ft">


<ft:objectadmin
	typename="cmLog"
	columnList="farcryTypename,FarcryFieldName,farcryObjectID,datetimecreated,datetimedatetimelastupdated"
	sortableColumns="farcryTypename,FarcryFieldName,datetimecreated,datetimedatetimelastupdated"
	lFilterFields="farcryTypename,FarcryFieldName,farcryObjectID"
	
	sqlOrderBy="datetimelastupdated DESC" />


<cfsetting enablecfoutputonly="false">