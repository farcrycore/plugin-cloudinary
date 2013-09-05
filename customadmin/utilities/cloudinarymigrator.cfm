<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: CDN Migration Tool --->

<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />


<cfif isdefined("url.copy_typename") and isdefined("url.copy_typename") and isdefined("url.copy_property")>
	
	<cfset stResult = structnew() />
	<cfset stResult["typename"] = url.copy_typename />
	<cfset stResult["objectid"] = url.copy_objectid />
	<cfset stResult["property"] = url.copy_property />
	
	<cfset stObj = application.fapi.getContentObject(typename=url.copy_typename,objectid=url.copy_objectid) />
	
	<cfif not findnocase("//res.cloudinary.com/",stObj[url.copy_property])>
		<cfif application.fc.lib.cdn.ioFileExists(location="images",file=stObj[url.copy_property])>
			<cfset stFile = application.formtools.image.oFactory.uploadToCloudinary(file=stObj[url.copy_property]) />
			<cfset stObj[url.copy_property] = mid(stFile.url,6,len(stFile.url)) & "?source=#urlencodedformat(stObj[url.copy_property])#" />
			
			<cfset application.fapi.setData(stProperties=stObj) />
			
			<cfset stResult["success"] = true />
		<cfelse>
			<cfset stResult["success"] = false />
			<cfset stResult["error"] = "File does not exist" />
		</cfif>
	<cfelse>
		<cfset stResult["success"] = false />
		<cfset stResult["error"] = "Already on Cloudinary" />
	</cfif>
	
	<cfcontent type="text/json" variable="#ToBinary( ToBase64( serializeJSON(stResult) ) )#" reset="Yes">
</cfif>


<cfparam name="form.copy" default="missing" />


<cfset qWrong = querynew("typename,typelabel,property,seq,objectid,label,filename,issource","varchar,varchar,varchar,integer,varchar,varchar,varchar,bit") />

<cfloop collection="#application.stCOAPI#" item="thistype">
	<cfif listcontains("type,rule",application.stCOAPI[thistype].class)>
		<cfloop collection="#application.stCOAPI[thistype].stProps#" item="thisprop">
			<cfif isdefined("application.stCOAPI.#thistype#.stProps.#thisprop#.metadata.ftType") and application.stCOAPI[thistype].stProps[thisprop].metadata.ftType eq "image">
				<cfset o = application.fapi.getContentType(typename=thistype) />
				<cfquery datasource="#application.dsn#" name="q">
					select		objectid,label,#thisprop#
					from		#application.dbowner##thistype#
					where		#thisprop#<>'' and #thisprop# not like <cfqueryparam cfsqltype="cf_sql_varchar" value="//res.cloudinary.com/%">
				</cfquery>
				
				<cfloop query="q">
					<cfset queryaddrow(qWrong) />
					<cfset querysetcell(qWrong,"typename",thistype) />
					<cfset querysetcell(qWrong,"typelabel",application.stCOAPI[thistype].displayname) />
					<cfset querysetcell(qWrong,"property",thisprop) />
					<cfset querysetcell(qWrong,"seq",application.stCOAPI[thistype].stProps[thisprop].metadata.ftSeq) />
					<cfset querysetcell(qWrong,"objectid",q.objectid) />
					<cfset querysetcell(qWrong,"label",q.label) />
					<cfset querysetcell(qWrong,"filename",listlast(q[thisprop][q.currentrow],"\/")) />
					<cfset querysetcell(qWrong,"issource",not structkeyexists(application.stCOAPI[thistype].stProps[thisprop].metadata,"ftSourceField") or not len(application.stCOAPI[thistype].stProps[thisprop].metadata.ftSourceField))>
				</cfloop>
			</cfif>
		</cfloop>
	</cfif>
</cfloop>

<cfquery dbtype="query" name="qWrong">
	select		*
	from		qWrong
	order by	typelabel, label, objectid, seq
</cfquery>

<admin:header>

<skin:htmlHead><cfoutput>
	<style>
		.selected, .selected td { background-color:##F9E6D4; }
		th.select, td.select { width:40px; }
		th.insource, td.insource, th.intarget, td.intarget { width:80px; }
		##files th.insource, td.insource { text-align:right; }
		td.insource, td.intarget, td.status { font-weight:bold; }
		.in-location-Yes { color:##01a100; }
		.in-location-No { color:##FF0000; }
		th.status, td.status { width:80px; }
		.status-not-applicable { color:##666666; }
		.status-success { color:##01a100; }
		.status-failure { color:##FF0000; }
	</style>
	<script type="text/javascript">
		var processing = false;
		var processingfile = -1;
		
		function getNextFile(){
			var file = $j("##files tbody input[name=files]:checked").first().parents("tr");
			
			if (file.size()){
				return file.data("file") - 1;
			}
			else{
				return -1;
			}
		}
		
		function copyFiles(action){
			if (action==="toggle" && processing && processingfile>-1){
				processing = false;
			}
			else if ((action==="next" && processing) || (action==="toggle" && !processing)){
				processing = true;
				processingfile = getNextFile();
				
				if (processingfile>-1){
					var info = $j("##file-"+(processingfile+1)+" input").val().split("|");
					$j.getJSON("#application.fapi.fixURL()#&copy_typename="+info[0]+"&copy_objectid="+info[1]+"&copy_property="+info[2],function(data){
						if (data.success){
							$j("##file-"+(processingfile+1))
								.removeClass("selected")
								.find("input[name=files]").attr("checked",null).end()
								.find(".status").removeClass("status-not-applicable").removeClass("status-success").removeClass("status-failure").addClass("status-success").html("Done").attr("title","").end();
						}
						else{
							$j("##file-"+(processingfile+1))
								.removeClass("selected")
								.find("input[name=files]").attr("checked",null).end()
								.find(".status").removeClass("status-not-applicable").removeClass("status-success").removeClass("status-failure").addClass("status-failure").html("Error").attr("title",data.error).end();
						}
						
						copyFiles("next");
					});
				}
				else{
					processing = false;
				}
			}
		};
	</script>
</cfoutput>
<skin:onReady><cfoutput>
	$j("##allfiles").click(function(){
		var tr = $j("##files tbody input[name=files]").attr("checked",$j(this).attr("checked")==="checked"?"checked":null).parents("tr.file");
		
		if ($j(this).attr("checked")==="checked")
			tr.addClass("selected");
		else
			tr.removeClass("selected")
	});
	$j("##files tbody tr").click(function(event){
		var target = $j(event.target), input = $j("input[name=files]",this), self = $j(this);
		
		if (!target.is("input"))
			input.attr("checked",input.attr("checked")==="checked"?null:"checked");
		
		if (input.attr("checked") === "checked")
			self.addClass("selected");
		else
			self.removeClass("selected");
	});
</cfoutput></skin:onReady>

<cfoutput>
	<h1><admin:resource key="webtop.utilities.cdnmigrator@title">Cloudinary Migration Tool</admin:resource></h1>
	<admin:resource key="webtop.utilities.coapisqllog.blurb@html">
		<p>This tool makes it easy to migrate existing images to Cloudinary hosting. #qWrong.recordcount# are not on Cloudinary now.</p>
	</admin:resource>
</cfoutput>

<ft:form>
	<ft:buttonPanel>
		<cfif qWrong.recordcount>
			<ft:button value="Copy Files" onclick="copyFiles('toggle');return false;" />
		</cfif>
	</ft:buttonPanel>
	
	<cfif qWrong.recordcount>
		<ft:field label="Files" bMultiField="true" class="blockLabels">
			<cfoutput>
				<table id="files" class="objectAdmin" style="width:100%;table-layout:fixed;">
					<thead>
						<tr>
							<th class="select"><input type="checkbox" id="allfiles"></th>
							<th class="type">Type</th>
							<th class="property">Property</th>
							<th class="title">Object</th>
							<th class="source">Source</th>
							<th class="file">File</th>
							<th class="status">Status</th>
						</tr>
					</thead>
					<tbody>
			</cfoutput>
			
			<cfloop query="qWrong">
				<cfoutput>
					<tr id="file-#qWrong.currentrow#" class="file <cfif qWrong.issource>alt</cfif>" data-file="#qWrong.currentrow#">
						<td class="select"><input type="checkbox" name="files" value="#qWrong.typename#|#qWrong.objectid#|#qWrong.property#"></td>
						<td class="type">#qWrong.typelabel#</td>
						<td class="property">#qWrong.property#</td>
						<td class="title">#qWrong.label#</td>
						<td class="source">#yesnoformat(qWrong.issource)#</td>
						<td class="file">#qWrong.filename#</td>
						<td class="status status-not-applicable">N/A</td>
					</tr>
				</cfoutput>
			</cfloop>
			
			<cfoutput>
					</tbody>
				</table>
			</cfoutput>
		</ft:field>
		
		<ft:buttonPanel>
			<ft:button value="Copy Files" onclick="copyFiles('toggle');return false;" />
		</ft:buttonPanel>
	</cfif>
</ft:form>

<admin:footer>

<cfsetting enablecfoutputonly="false" />