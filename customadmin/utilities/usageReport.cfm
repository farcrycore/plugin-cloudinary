<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Cloudinary Usage report --->


<cfset stResults = application.fc.lib.cloudinary.getUsageReport()>
<cfset checks = "transformations,objects,bandwidth,storage">

<cfoutput>

<style>
dd { 
  display: block;
  margin-left: 40px;
}
</style>
<h1>
<i class="fa fa-file-text"></i>
Cloudinary Usage Report
</h1>

<h2>Plan: #stResults.plan#</h2>
<table class="farcry-objectadmin table table-striped table-hover">
<thead>
	<tr>
		<th style="width:97%;">&nbsp;</th>
		<th style="width:1%;">Usage</th>
		<th style="width:1%;">Limit</th>
		<th style="width:1%;">Percentage</th>
	</tr>
</thead>
<tbody>
<cfloop list="#checks#" item="check">
	<tr>
		<td style="text-transform: capitalize;font-weight: bold;">#check#</td>
		<td style="text-align: right;">#NumberFormat(stResults[check]['usage'])#</td>
		<td style="text-align: right;">#NumberFormat(stResults[check]['limit'])#</td>
		<td style="text-align: right;">#stResults[check]['used_percent']#%</td>
	</tr>
</cfloop>
</tbody>
</table>

<ul>
<li><strong>Requests:</strong> #NumberFormat(stResults['requests'])#</li>
<li><strong>Resources:</strong> #NumberFormat(stResults['resources'])#</li>
<li><strong>Derived Resources:</strong> #NumberFormat(stResults['derived_resources'])#</li>
<li><strong>Media Limits</strong>
	<ul>
		<li><strong>image max size bytes:</strong> #NumberFormat(stResults['media_limits']['image_max_size_bytes'])#</li>
		<li><strong>video max size bytes:</strong> #NumberFormat(stResults['media_limits']['video_max_size_bytes'])#</li>
		<li><strong>raw max size bytes:</strong> #NumberFormat(stResults['media_limits']['raw_max_size_bytes'])#</li>
		<li><strong>image max px:</strong> #NumberFormat(stResults['media_limits']['image_max_px'])#</li>
		<li><strong>asset max total px:</strong> #NumberFormat(stResults['media_limits']['asset_max_total_px'])#</li>
	</ul>
</li>
<li><strong>Last Updated:</strong> #stResults['last_updated']#</li>
</ul>

</cfoutput>


<cfsetting enablecfoutputonly="false">