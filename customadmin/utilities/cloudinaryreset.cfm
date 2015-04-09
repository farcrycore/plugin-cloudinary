<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: CDN Migration Tool --->

<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />


<cfif isdefined("url.reset_typename") and isdefined("url.reset_typename") and isdefined("url.reset_property")>
	
	<cfset stResult = structnew() />
	<cfset stResult["typename"] = url.reset_typename />
	<cfset stResult["objectid"] = url.reset_objectid />
	<cfset stResult["property"] = url.reset_property />
	
	<cfset stObj = application.fapi.getContentObject(typename=url.reset_typename,objectid=url.reset_objectid) />
	
	<cfif application.fapi.getPropertyMetadata(url.reset_typename, url.reset_property, "ftType", "") eq "image" and len(application.fapi.getPropertyMetadata(url.reset_typename, url.reset_property, "ftSourceField", ""))>
		<cfset sourceField = listfirst(application.fapi.getPropertyMetadata(url.reset_typename, url.reset_property, "ftSourceField"),":") />
		<cfset stFP = {} />
		<cfset stFP[sourceField] = {
			value = stObj[sourceField]
		} />
		<cfset stFP[url.reset_property] = structnew() />
		<cfset oldVal = stObj[url.reset_property] />
		<cfset stObj[url.reset_property] = "" />

		<cftry>
			<cfset stObj = application.formtools.image.oFactory.ImageAutoGenerateBeforeSave(typename=stObj.typename,stProperties=stObj,stFields=application.stCOAPI[url.reset_typename].stProps,stFormPost=stFP) />

			<cfif stObj[url.reset_property] neq oldVal>
				<cfset application.fapi.setData(stProperties=stObj) />
			</cfif>

			<cfset stResult["success"] = true />
			<cfset stResult["file"] = stObj[url.reset_property] />

			<cfcatch>
				<cfset stResult["success"] = false />
				<cfset stResult["error"] = cfcatch.message />
			</cfcatch>
		</cftry>
	</cfif>
	
	<cfcontent type="text/json" variable="#ToBinary( ToBase64( serializeJSON(stResult) ) )#" reset="Yes">
</cfif>


<cfparam name="form.copy" default="missing" />
<cfparam name="form.step" default="select-type" />


<admin:header>

<cfif form.step eq "select-type">
	<cfset qTypes = querynew("typename,typelabel,properties") />

	<cfloop collection="#application.stCOAPI#" item="thistype">
		<cfif listcontains("type,rule",application.stCOAPI[thistype].class)>
			<cfloop collection="#application.stCOAPI[thistype].stProps#" item="thisprop">
				<cfif application.fapi.getPropertyMetadata(thistype, thisprop, "ftType", "string") eq "image" and len(application.fapi.getPropertyMetadata(thistype, thisprop, "ftSourceField", ""))>
					<cfif qTypes.typename[qTypes.recordcount] neq thistype>
						<cfset queryaddrow(qTypes) />
					</cfif>

					<cfset querysetcell(qTypes,"typename",thistype) />
					<cfset querysetcell(qTypes,"typelabel",application.stCOAPI[thistype].displayname) />
					<cfset querysetcell(qTypes,"properties",listappend(qTypes.properties[qTypes.recordcount],application.fapi.getPropertyMetadata(thistype, thisprop, "ftLabel", thisprop))) />
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>

	<cfquery dbtype="query" name="qTypes">
		select * from qTypes order by typelabel
	</cfquery>

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
	</cfoutput></skin:htmlHead>

	<cfoutput>
		<h1><admin:resource key="webtop.utilities.cdnmigrator@title">Cloudinary Reset Tool</admin:resource></h1>
		<admin:resource key="webtop.utilities.coapisqllog.blurb@html">
			<p>This tool makes it easy to reset stored Cloudinary URLs.</p>
		</admin:resource>
	</cfoutput>

	<ft:form>
		<ft:buttonPanel>
			<ft:button value="Select Types" />
		</ft:buttonPanel>
		
		<cfoutput><input type="hidden" name="step" value="review-files"></cfoutput>

		<ft:field label="Types" bMultiField="true" class="blockLabels">
			<cfoutput>
				<table id="files" class="objectAdmin" style="width:100%;table-layout:fixed;">
					<thead>
						<tr>
							<th class="select"></th>
							<th class="type">Type</th>
							<th class="property">Properties</th>
						</tr>
					</thead>
					<tbody>
			</cfoutput>
			
			<cfoutput query="qTypes">
				<tr id="type-#qTypes.currentrow#" class="type <cfif qTypes.currentrow mod 2>alt</cfif>">
					<td class="select"><input type="checkbox" name="types" value="#qTypes.typename#"></td>
					<td class="type">#qTypes.typelabel#</td>
					<td class="property">#replace(qTypes.properties,",",", ","ALL")#</td>
				</tr>
			</cfoutput>

			<cfoutput>
					</tbody>
				</table>
			</cfoutput>

			<ft:buttonPanel>
				<ft:button value="Select Types" />
			</ft:buttonPanel>
		</ft:field>
	</ft:form>

<cfelseif form.step eq "review-files">
	<cfset qWrong = querynew("typename,typelabel,property,seq,objectid,label,filename","varchar,varchar,varchar,integer,varchar,varchar,varchar") />

	<cfloop collection="#application.stCOAPI#" item="thistype">
		<cfif listfindnocase(form.types,thistype) and listcontains("type,rule",application.stCOAPI[thistype].class)>
			<cfloop collection="#application.stCOAPI[thistype].stProps#" item="thisprop">
				<cfif application.fapi.getPropertyMetadata(thistype, thisprop, "ftType", "string") eq "image" and len(application.fapi.getPropertyMetadata(thistype, thisprop, "ftSourceField", ""))>
					<cfset o = application.fapi.getContentType(typename=thistype) />
					<cfquery datasource="#application.dsn#" name="q">
						select		objectid,label,#thisprop#
						from		#application.dbowner##thistype#
					</cfquery>
					
					<cfloop query="q">
						<cfset queryaddrow(qWrong) />
						<cfset querysetcell(qWrong,"typename",thistype) />
						<cfset querysetcell(qWrong,"typelabel",application.stCOAPI[thistype].displayname) />
						<cfset querysetcell(qWrong,"property",thisprop) />
						<cfset querysetcell(qWrong,"seq",application.stCOAPI[thistype].stProps[thisprop].metadata.ftSeq) />
						<cfset querysetcell(qWrong,"objectid",q.objectid) />
						<cfset querysetcell(qWrong,"label",q.label) />
						<cfset querysetcell(qWrong,"filename",q[thisprop][q.currentrow]) />
					</cfloop>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>

	<cfquery dbtype="query" name="qWrong">
		select		*
		from		qWrong
		order by	typelabel, property, label, objectid, seq
	</cfquery>

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
						$j.getJSON("#application.fapi.fixURL()#&reset_typename="+info[0]+"&reset_objectid="+info[1]+"&reset_property="+info[2],function(data){
							if (data.success){
								$j("##file-"+(processingfile+1))
									.removeClass("selected")
									.find("input[name=files]").attr("checked",null).end()
									.find(".status").removeClass("status-not-applicable").removeClass("status-success").removeClass("status-failure").addClass("status-success").html("Done").attr("title","").end()
									.find(".file").html(data.file);
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
		<h1><admin:resource key="webtop.utilities.cdnmigrator@title">Cloudinary Reset Tool</admin:resource></h1>
		<admin:resource key="webtop.utilities.coapisqllog.blurb@html">
			<p>This tool makes it easy to reset stored Cloudinary URLs.</p>
		</admin:resource>
	</cfoutput>

	<ft:form>
		<ft:buttonPanel>
			<cfif qWrong.recordcount>
				<ft:button value="Reset URLs" onclick="copyFiles('toggle');return false;" />
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
								<th class="file">File</th>
								<th class="status">Status</th>
							</tr>
						</thead>
						<tbody>
				</cfoutput>
				
				<cfoutput query="qWrong">
					<tr id="file-#qWrong.currentrow#" class="file <cfif qWrong.currentrow mod 2>alt</cfif>" data-typename="#qWrong.typename#" data-property="#qWrong.property#" data-file="#qWrong.currentrow#">
						<td class="select"><input type="checkbox" name="files" value="#qWrong.typename#|#qWrong.objectid#|#qWrong.property#"></td>
						<td class="type">#qWrong.typelabel# (<a class="select-by-typename" data-typename="#qWrong.typename#">select all</a>)</td>
						<td class="property">#qWrong.property# (<a class="select-by-property" data-typename="#qWrong.typename#" data-property="#qWrong.property#">select all</a>)</td>
						<td class="title">#qWrong.label#</td>
						<td class="file">#qWrong.filename#</td>
						<td class="status status-not-applicable">N/A</td>
					</tr>
				</cfoutput>
				
				<cfoutput>
						</tbody>
					</table>
					<script>
						$j(".select-by-typename").bind("click",function(e){
							var self = $j(this);
							var typename = self.data("typename");

							$j('tr[data-typename='+typename+'] input[type=checkbox]')
								.prop('checked',true);

							e.stopPropagation();
							e.preventDefault();
						});
						$j(".select-by-property").bind("click",function(e){
							var self = $j(this);
							var typename = self.data("typename");
							var property = self.data("property");

							$j('tr[data-typename='+typename+'][data-property='+property+'] input[type=checkbox]')
								.prop('checked',true);

							e.stopPropagation();
							e.preventDefault();
						});
					</script>
				</cfoutput>
			</ft:field>
			
			<ft:buttonPanel>
				<ft:button value="Copy Files" onclick="copyFiles('toggle');return false;" />
			</ft:buttonPanel>
		</cfif>
	</ft:form>
</cfif>

<admin:footer>

<cfsetting enablecfoutputonly="false" />