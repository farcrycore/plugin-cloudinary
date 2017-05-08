

<cfoutput>
<h2>Undo - Restore to origional stage</h2>

<pre>
update <yaffa_dsp>.#stObj.FARCRYTYPENAME#
set #stObj.FARCRYFIELDNAME# = '#stObj.URLCLOUDINARY#'
where objectid = '#stObj.FARCRYOBJECTID#'
</pre>
	
	
<h4>URLCLOUDINARY</h4>
<img src="http:#stObj.URLCLOUDINARY#" alt="URLCLOUDINARY"><br />

<h4>URLS3</h4>
<img src="#application.fapi.getImageWebRoot()##stObj.URLS3#"      alt="URLS3"><br />

</cfoutput>

<cfdump var="#stObj#" label="cmLog">