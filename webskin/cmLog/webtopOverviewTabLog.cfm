<cfsetting enablecfoutputonly="true">
<!--- @@displayname: Migrator Log --->


<cfoutput>
<h2>Undo - Restore to origional stage</h2>

<pre>
update <yaffa_dsp>.#stObj.FARCRYTYPENAME#
set #stObj.FARCRYFIELDNAME# = '#stObj.URLCLOUDINARY#'
where objectid = '#stObj.FARCRYOBJECTID#'
</pre>

</cfoutput>
<cfdump var="#stObj#" label="cmLog">


<cfsetting enablecfoutputonly="false">