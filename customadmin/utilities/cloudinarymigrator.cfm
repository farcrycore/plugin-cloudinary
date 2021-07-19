<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: CDN Migration Tool --->

<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfif isdefined("url.copy_typename") and isdefined("url.copy_property") and isdefined("url.copy_objectid") and isValid("uuid", url.copy_objectid)>
	<cfset stResult = structnew() />
	<cfset stResult["typename"] = url.copy_typename />
	<cfset stResult["objectid"] = url.copy_objectid />
	<cfset stResult["property"] = url.copy_property />

	<cfset stObj = application.fapi.getContentObject(typename=url.copy_typename,objectid=url.copy_objectid) />

	<cfif not findnocase("//res.cloudinary.com/",stObj[url.copy_property])>
		<cfif application.fc.lib.cdn.ioFileExists(location="images",file=stObj[url.copy_property])>
			<cftry>
				<cfset original = stObj[url.copy_property] />
				<cfset stFile = application.formtools.image.oFactory.uploadToCloudinary(file=original) />
				<cfif isStruct(stFile)>
					<cfset stObj[url.copy_property] = mid(stFile.url,6,len(stFile.url)) />
				<cfelse>
					<cfset stObj[url.copy_property] = stFile />
				</cfif>

				<cfif left(stObj[url.copy_property], 2) eq "//">
					<cfset stObj[url.copy_property] &= "?source=#urlencodedformat(original)#" />
				</cfif>

				<cfset st = application.fapi.setData(stProperties=stObj) />

				<cfif st.bSuccess>
					<cfset stResult["success"] = true />
					<cfset stResult["file"] = stObj[url.copy_property] />
				<cfelse>
					<cfset stResult["success"] = false />
					<cfset stResult["error"] = st.message />
					<cfset stResult["file"] = stObj[url.copy_property] />
				</cfif>

				<cfcatch>
					<cfset stResult["success"] = false />
					<cfset stResult["error"] = cfcatch.message & " - " & cfcatch.detail />
					<cfif isJson(cfcatch.detail)>
						<cfset detail = deserializeJSON(cfcatch.detail) />
						<cfif isStruct(detail) && structKeyExists(detail, "error") && structKeyExists(detail.error, "message")>
							<cfset stResult["error"] = detail.error.message />
						</cfif>
					</cfif>
				</cfcatch>
			</cftry>
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

<cfif isdefined("url.details_typename") and isdefined("url.details_property")>
	<cfset thistype = url.details_typename />
	<cfset thisprop = url.details_property />

	<cfquery datasource="#application.dsn#" name="q">
		select		'#thistype#' as typename,
					'#application.stCOAPI[thistype].displayname#' as typelabel,
					'#thisprop#' as property,
					<cfif len(application.stCOAPI[thistype].stProps[thisprop].metadata.ftSeq)>#application.stCOAPI[thistype].stProps[thisprop].metadata.ftSeq#<cfelse>0</cfif> as seq,
					CASE
						WHEN CHARINDEX('/', REVERSE(#thisprop#)) - 1 > 0 THEN RIGHT(#thisprop#, CHARINDEX('/', REVERSE(#thisprop#)) - 1)
						ELSE ''
					END AS filename,
					#thisprop#,
					objectid,
					label,
					<cfif not structkeyexists(application.stCOAPI[thistype].stProps[thisprop].metadata,"ftSourceField") or not len(application.stCOAPI[thistype].stProps[thisprop].metadata.ftSourceField)>1<cfelse>0</cfif> as isSource
		from		#application.dbowner##thistype#
		where		#thisprop#<>'' and #thisprop# not like <cfqueryparam cfsqltype="cf_sql_varchar" value="//res.cloudinary.com/%">
	</cfquery>

	<cfset aResult = [] />

	<cfloop query="q">
		<cfset arrayAppend(aResult, queryGetRow(q, q.currentrow)) />
	</cfloop>

	<cfcontent type="text/json" variable="#ToBinary( ToBase64( serializeJSON(aResult) ) )#" reset="Yes">
</cfif>


<cfparam name="form.copy" default="missing" />


<cfset first = true>
<cfquery datasource="#application.dsn#" name="qWrong">
	<cfloop collection="#application.stCOAPI#" item="thistype">
		<cfset o = application.fapi.getContentType(typename=thistype) />

		<cfif listcontains("type,rule",application.stCOAPI[thistype].class)>
			<cfloop collection="#application.stCOAPI[thistype].stProps#" item="thisprop">
				<cfif isdefined("application.stCOAPI.#thistype#.stProps.#thisprop#.metadata.ftType") and application.stCOAPI[thistype].stProps[thisprop].metadata.ftType eq "image">
					<cfoutput>
						<cfif not first>UNION</cfif>

						select		'#thistype#' as typename,
									'#application.stCOAPI[thistype].displayname#' as typelabel,
									'#thisprop#' as property,
									<cfif len(application.stCOAPI[thistype].stProps[thisprop].metadata.ftSeq)>#application.stCOAPI[thistype].stProps[thisprop].metadata.ftSeq#<cfelse>0</cfif> as seq,
									count(objectid) as wrongcount,
									<cfif not structkeyexists(application.stCOAPI[thistype].stProps[thisprop].metadata,"ftSourceField") or not len(application.stCOAPI[thistype].stProps[thisprop].metadata.ftSourceField)>1<cfelse>0</cfif> as isSource
						from		#application.dbowner##thistype#
						where		#thisprop#<>'' and #thisprop# not like '//res.cloudinary.com/%'
					</cfoutput>

					<cfset first = false>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
</cfquery>

<cfquery dbtype="query" name="qWrong">
	select		*
	from		qWrong
	where 		wrongcount > 0
	order by	typelabel, seq
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
		var filecounter = 1;

		function getNextFiles(cb) {
			var input = $j("##files tbody .file-summary input[name=files]:checked").first();
			var info = input.val().split("|");
			var first = null;

			if (input.size() === 0) {
				cb(null);
			}

			$j.getJSON("#application.fapi.fixURL()#&details_typename="+info[0]+"&details_property="+info[1],function(data){
				first = { index:filecounter, typename:info[0], objectid:data[0].objectid, property:info[1] };

				input.parents("tr").replaceWith(data.map(function(v, i){
					return [
						'<tr id="file-', filecounter + i, '" class="file file-detail ', v.isSource ? 'alt' : '','" data-file="', filecounter + i, '">',
						'	<td class="select"><input type="checkbox" name="files" value="', info[0], '|', v.objectid, '|', info[1], '" checked></td>',
						'	<td class="type">', v.typelabel, '</td>',
						'	<td class="property">', v.property, '</td>',
						'	<td class="title">', v.label, '</td>',
						'	<td class="file">', v.filename, '</td>',
						'	<td class="source">', v.isSource ? 'Yes' : 'No', '</td>',
						'	<td class="status status-not-applicable">N/A</td>',
						'</tr>'
					].join("");
				}).join(""));

				filecounter += data.length;

				cb(first);
			});
		}

		function getNextFile(cb){
			if ($j("##files tbody .file-detail input[name=files]:checked").length === 0 && $j("##files tbody .file-summary input[name=files]:checked").length > 0) {
				return getNextFiles(cb);
			}

			var file = $j("##files .file-detail input[name=files]:checked").first().parents("tr");

			if (file.size()){
				var info = file.find("input").val().split("|");

				cb({
					index: file.data("file"),
					typename: info[0],
					objectid: info[1],
					property: info[2]
				});
			}
			else{
				cb(cb);
			}
		}

		function copyFiles(action){
			if (action==="toggle" && processing && processingfile>-1){
				processing = false;
			}
			else if ((action==="next" && processing) || (action==="toggle" && !processing)){
				processing = true;
				getNextFile(function(processingfile) {
					if (processingfile !== null){
						$j.getJSON("#application.fapi.fixURL()#&copy_typename="+processingfile.typename+"&copy_objectid="+processingfile.objectid+"&copy_property="+processingfile.property,function(data){
							if (data.success){
								$j("##file-"+processingfile.index)
									.removeClass("selected")
									.find("input[name=files]").prop("checked",null).end()
									.find(".status").removeClass("status-not-applicable").removeClass("status-success").removeClass("status-failure").addClass("status-success").html("Done").attr("title","").end();
							}
							else{
								$j("##file-"+processingfile.index)
									.removeClass("selected")
									.find("input[name=files]").prop("checked",null).end()
									.find(".status").removeClass("status-not-applicable").removeClass("status-success").removeClass("status-failure").addClass("status-failure").html("Error").attr("title",data.error).end();
							}

							copyFiles("next");
						});
					}
					else{
						processing = false;
					}
				});
			}
		};
	</script>
</cfoutput>
<skin:onReady><cfoutput>
	$j("##allfiles").click(function(){
		var tr = $j("##files tbody input[name=files]").prop("checked",$j(this).prop("checked")?"checked":null).parents("tr.file");

		if ($j(this).prop("checked"))
			tr.addClass("selected");
		else
			tr.removeClass("selected")
	});
	$j("##files tbody tr").click(function(event){
		var target = $j(event.target), input = $j("input[name=files]",this), self = $j(this);

		if (!target.is("input"))
			input.prop("checked",input.prop("checked")?null:"checked");

		if (input.prop("checked"))
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
							<th class="file">Files</th>
							<th class="source">Source</th>
							<th class="status">Status</th>
						</tr>
					</thead>
					<tbody>
			</cfoutput>

			<cfloop query="qWrong">
				<cfoutput>
					<tr class="file file-summary <cfif qWrong.issource>alt</cfif>">
						<td class="select"><input type="checkbox" name="files" value="#qWrong.typename#|#qWrong.property#"></td>
						<td class="type">#qWrong.typelabel#</td>
						<td class="property">#qWrong.property#</td>
						<td class="title"></td>
						<td class="file">#qWrong.wrongcount#</td>
						<td class="source">#yesnoformat(qWrong.issource)#</td>
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