<cfcomponent>
	<cfscript>
	
	public any function init() {
		return this;
	}

	public string function getAPIEndpoint() {
		return "//" & getAPIDomain() & "/" & getCloudName();
	}

	public string function getAPIDomain() {
		return "res.cloudinary.com";
	}

	public string function getCloudName() {

		var cloudName = application.fapi.getConfig("cloudinary", "cloudName", "");
		if (!len(cloudName)) {
			throw "Cloudinary API configuration is missing";
		}

		return cloudName;
	}

	public string function getTransform(numeric width=0, numeric height=0, string crop="FitInside", string format=""){
		
		var transform = "fl_keep_iptc";
		var pixels = "";
		
		switch (lcase(arguments.crop)){
			case "forcesize":
				// Simply force the resize of the image into the width/height provided
				transform = listappend(transform,"c_scale");
				
				if (arguments.width gt 0){
					transform = listappend(transform,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					transform = listappend(transform,"h_#arguments.height#");
				}

				break;
			
			case "fitinside":
				transform = listappend(transform,"c_fit");
				
				if (arguments.width gt 0){
					transform = listappend(transform,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					transform = listappend(transform,"h_#arguments.height#");
				}

				break;
			
			case "croptofit":
				transform = listappend(transform,"c_fill");
				
				if (arguments.width gt 0){
					transform = listappend(transform,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					transform = listappend(transform,"h_#arguments.height#");
				}
				
				break;
	
			case "pad":
				transform = listappend(transform,"c_pad");
				
				if (arguments.width gt 0){
					transform = listappend(transform,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					transform = listappend(transform,"h_#arguments.height#");
				}
				
				break;
			
			case "center": 
			case "topleft": 
			case "topcenter": 
			case "topright": 
			case "left": 
			case "right": 
			case "bottomleft": 
			case "bottomcenter": 
			case "bottomright":
				transform = listappend(transform,"c_fill");
				
				if (arguments.width gt 0){
					transform = listappend(transform,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					transform = listappend(transform,"h_#arguments.height#");
				}
				
				switch (arguments.crop){
					case "center":
						transform = listappend(transform,"g_faces:center");
						break;
					case "topleft":
						transform = listappend(transform,"g_north_west");
						break;
					case "topcenter":
						transform = listappend(transform,"g_north");
						break;
					case "topright":
						transform = listappend(transform,"g_north_east");
						break;
					case "left":
						transform = listappend(transform,"g_west");
						break;
					case "right":
						transform = listappend(transform,"g_east");
						break;
					case "bottomleft":
						transform = listappend(transform,"g_south_west");
						break;
					case "bottomcenter":
						transform = listappend(transform,"g_south");
						break;
					case "bottomright":
						transform = listappend(transform,"g_south_east");
						break;
				}

				break;
			
			default:
				if (refind("^\d+,\d+-\d+,\d+$",arguments.crop)){
					pixels = listtoarray(arguments.crop,",-");
					
					// crop to selected section
					transform = listappend(transform,"x_#pixels[1]#,y_#pixels[2]#,w_#pixels[3]-pixels[1]#,h_#pixels[4]-pixels[2]#,c_crop");
					
					// resize selected section to required size
					transform = transform & "/c_fit";
					
					if (arguments.Width gt 0){
						transform = listappend(transform,"w_#arguments.width#");
					}
					
					if (arguments.Height gt 0){
						transform = listappend(transform,"h_#arguments.height#");
					}
				}
		}
		
		switch (arguments.format){
			case "png":
				transform = listappend(transform,"f_png");
				break;
			case "auto":
				transform = listappend(transform, "f_auto");
		}

		return transform;
	}

	public struct function getURLInformation(required string file) {

		var apiDomain = getAPIDomain();
		var cloudName = getCloudName();
		var uploadVia = application.fapi.getConfig("cloudinary", "uploadVia", "post");
		var autoUploadFolder = application.fapi.getConfig("cloudinary", "autoUploadFolder", "/nothing___here");

		var apiURLPrefix = "//" & apiDomain & "/" & cloudName & "/image";

		var reAPI = "^//" & replace(apiDomain, '.', '\.', 'ALL') & "/" & replace(cloudName, '.', '\.', 'ALL') & "/image";
		var reCDN = reReplace(replaceList(application.fc.lib.cdn.ioGetFileLocation(location="images", file="", bRetrieve=true, protocol="http").path, ".,?,+", "\.,\?,\+"), "http:", "^(https?:)?");
		var reFetch = reAPI & "/fetch(?:/([^/]+))?/(http.*)$";
		var reAuto = reAPI & "/upload(?:/([^/]+))?" & autoUploadFolder & "(/.*)$";
		var rePost = reAPI & "/upload(?:/([^/]+))?(/[^/\?]+)(\?.*|$)";

		var stResult = {
			"type" = "unknown",
			"file" = arguments.file,
			"transformation" = "",
			"untransformed" = arguments.file,
			"template" = "",
			"source" = ""
		};

		if (refindnocase(reFetch, arguments.file)){
			stResult["type"] = "fetch";
			stResult["source"] = rereplacenocase(urlDecode(rereplace(arguments.file, reFetch, "\2")), reCDN, "/");
			stResult["transformation"] = rereplace(arguments.file, reFetch, "\1");
			if (len(stResult["transformation"])){
				stResult["untransformed"] = apiURLPrefix & "/fetch/" & rereplace(arguments.file, reFetch, "\2");
			}
			stResult["template"] = rereplace(stResult.untransformed, "/fetch/", "/fetch/{transformation}/");
		}

		else if (len(autoUploadFolder) and refindnocase(reAuto, arguments.file)){
			stResult["type"] = "auto";
			stResult["source"] = rereplacenocase(arguments.file, reAuto, "\2");
			stResult["transformation"] = rereplace(arguments.file, reAuto, "\1");
			if (len(stResult["transformation"])){
				stResult["untransformed"] = apiURLPrefix & "/upload" & autoUploadFolder & stResult.source;
			}
			stResult["template"] = rereplace(stResult.untransformed, "/upload" & autoUploadFolder & "/", "/upload/{transformation}" & autoUploadFolder & "/");
		}

		else if (refindnocase(rePost, arguments.file)){
			stResult["type"] = "post";
			if (refindnocase("\?_?source=", arguments.file)){
				stResult["source"] = urldecode(rereplacenocase(arguments.file, ".*\?_?source=([^&]+).*","\1"));

				if (refindnocase("\?source=", arguments.file)){
					stResult["dependant"] = false;
				}
				else {
					stResult["dependant"] = true;
				}
			}
			stResult["transformation"] = rereplace(arguments.file, rePost, "\1");
			if (len(stResult.source)){
				stResult["transformation"] = stResult["transformation"] & "?" & (stResult.dependant ? "_" : "") & "source=" & stResult.source;
			}
			if (len(stResult["transformation"])){
				stResult["untransformed"] = apiURLPrefix & "/upload" & rereplace(arguments.file, rePost, "\2") & rereplace(arguments.file, rePost, "\3");
			};
			stResult["template"] = rereplace(stResult.untransformed, "/upload/", "/upload/{transformation}/");
		}

		else if (refind(reCDN, arguments.file)) {
			stResult["source"] = rereplace(arguments.file, reCDN, "/");
			if (uploadVia eq "fetch"){
				stResult["type"] = "fetch";
				stResult["untransformed"] = apiURLPrefix & "/fetch/" & urlEncodedFormat(arguments.file);
				stResult["template"] = rereplace(stResult.untransformed, "/fetch/", "/fetch/{transformation}/");
			}
			else if (uploadVia eq "auto"){
				stResult["type"] = "auto";
				stResult["untransformed"] = apiURLPrefix & "/upload" & stResult.source;
				stResult["template"] = rereplace(stResult.untransformed, "/upload/", "/upload/{transformation}/");
			}
		}

		else {
			stResult["source"] = arguments.file;
			if (uploadVia eq "fetch"){
				stResult["type"] = "fetch";
				stResult["untransformed"] = apiURLPrefix & "/fetch/" & urlEncodedFormat(application.fc.lib.cdn.ioGetFileLocation(location="images", file=arguments.file, bReceive=true, protocol="http").path);
				stResult["template"] = rereplace(stResult.untransformed, "/fetch/", "/fetch/{transformation}/");
			}
			else if (uploadVia eq "auto"){
				stResult["type"] = "auto";
				stResult["untransformed"] = apiURLPrefix & "/upload" & stResult.source;
				stResult["template"] = rereplace(stResult.untransformed, "/upload/", "/upload/{transformation}/");
			}
		}

		return stResult;
	}
	
	public string function transform(required string file, required any transformation) {
		var stInfo = getURLInformation(arguments.file);

		if (isStruct(arguments.transformation)){
			arguments.transformation = getTransform(argumentCollection=arguments.transformation);
		}

		return replace(stInfo.template, "{transformation}", arguments.transformation);
	}

	public string function getID(required string file){
		
		return urldecode(listfirst(listlast(listfirst(arguments.file,"?"),"/"),"."));
	}
	
	public string function getSource(required string file){
		var stInfo = getURLInformation(arguments.file);

		return stInfo.source;
	}

	
	public string function fetch(required string file) {
		var endpoint = getAPIEndpoint();

		// create a new Cloudinary URL
		if (len(arguments.file) gt 2){
			if (left(arguments.file, 2) == "//") {
				arguments.file = "http:" & arguments.file;
			}
			else if (left(arguments.file, 1) == "/") {
				arguments.file = application.fc.lib.cdn.ioGetFileLocation(location="images", file=arguments.file, bRetrieve=true, protocol="http").path;
			}
		}

		return "#endpoint#/image/fetch/#urlencodedformat(arguments.file)#";
	}

	public string function autoUpload(required string file) {
		var endpoint = getAPIEndpoint();
		var autoUploadFolder = application.fapi.getConfig("cloudinary", "autoUplaodFolder", "");

		return "#endpoint#/image/upload/#autoUploadFolder##arguments.file#";
	}	

	</cfscript>


	<cffunction name="upload" access="public" output="false" returntype="struct">
		<cfargument name="file" type="string" required="true">
		<cfargument name="publicID" type="string" required="true">
		<cfargument name="transformation" type="string" required="true">

		<cfset var sigTimestamp = DateDiff('s', CreateDate(1970,1,1), now())>
		<cfset var sigSignature = "">
		<cfset var stResult = structnew()>
		<cfset var stResponse = structnew()>
		<cfset var cloudName = application.fapi.getConfig("cloudinary", "cloudName", "")>
		<cfset var apiKey = application.fapi.getConfig("cloudinary", "apiKey", "")>
		<cfset var apiSecret = application.fapi.getConfig("cloudinary", "apiSecret", "")>
		
		<cfif not len(cloudName) or not len(apiKey) or not len(apiSecret)>
			<cfthrow message="Cloudinary has not been configured - add the Cloud Name, API Key and API Secret">
		</cfif>
		
		<cfset sigSignature = lcase( hash( "public_id=#arguments.publicID#&timestamp=#sigTimestamp##apiSecret#" ,"SHA" ) )>
		
		<!--- UPLOAD TO CLOUDINARY --->
		<cfhttp url="https://api.cloudinary.com/v1_1/#cloudName#/image/upload" method="POST" multipart="true" result="stResponse">
			<cfhttpparam type="formfield" name="api_key" value="#apiKey#">
			<cfhttpparam type="formfield" name="public_id" value="#arguments.publicID#">
			<cfhttpparam type="formfield" name="timestamp" value="#sigTimestamp#">
			<cfhttpparam type="formfield" name="signature" value="#trim(sigSignature)#">
			<cfif len(arguments.transformation)>
				<cfhttpparam type="formfield" name="transformation" value="#arguments.transformation#">
			</cfif>
			<cfhttpparam type="file" name="file" file="#application.fc.lib.cdn.ioReadFile(location='images',file=arguments.file,datatype='image').source#">
		</cfhttp>
		
		<cfif isjson(stResponse.filecontent)>
			<cfset stResult = deserializejson(stResponse.filecontent)>
			<cfset stResult["urlWithSource"] = mid(stResult.url,6,len(stResult.url)) & "?source=#urlencodedformat(arguments.file)#">
		</cfif>
		
		<cfif stResponse.StatusCode neq "200 Ok">
			<cfif structkeyexists(stResult,"error")>
				<!--- Cloudinary threw error, returned information --->
				<cfthrow message="Error uploading to Cloudinary: #stResult.error.message#" detail="#stResponse.filecontent.toString()#">
			<cfelse>
				<!--- Cloudinary threw error, no information --->
				<cfthrow message="Error uploading to Cloudinary" detail="#stResponse.filecontent.toString()#">
			</cfif>
		</cfif>
		
		<cfreturn stResult>
	</cffunction>



	<cffunction name="delete" access="public" output="false" returntype="struct">
		<cfargument name="file" type="string" required="true">

		<cfset var sigTimestamp = DateDiff('s', CreateDate(1970,1,1), now())>
		<cfset var sigSignature = "">
		<cfset var stResult = structnew()>
		<cfset var stResponse = structnew()>
		<cfset var publicID = "">
		<cfset var stInfo = getURLInformation(arguments.file)>

		<cfset var cloudName = application.fapi.getConfig("cloudinary", "cloudName", "")>
		<cfset var apiKey = application.fapi.getConfig("cloudinary", "apiKey", "")>
		<cfset var apiSecret = application.fapi.getConfig("cloudinary", "apiSecret", "")>
		
		<cfif not len(cloudName) or not len(apiKey) or not len(apiSecret)>
			<cfthrow message="Cloudinary has not been configured - add the Cloud Name, API Key and API Secret">
		</cfif>
		
		<cfif stInfo.type neq "post">
			<cfreturn {}>
		</cfif>

		<cfset publicID = getID(arguments.file)>
		<cfset sigSignature = lcase( hash( "public_id=#publicID#&timestamp=#sigTimestamp##apiSecret#" ,"SHA" ) )>
		
		<!--- DELETE FROM CLOUDINARY --->
		<cfhttp url="https://api.cloudinary.com/v1_1/#cloudName#/resources/image/upload?public_ids=#publicID#" method="DELETE" username="#apiKey#" password="#apiSecret#">
		
		<cfif isjson(stResponse.filecontent)>
			<cfset stResult = deserializejson(stResponse.filecontent)>
		</cfif>
		
		<cfif stResponse.StatusCode neq "200 Ok">
			<cfif structkeyexists(stResult,"error")>
				<!--- Cloudinary threw error, returned information --->
				<cfthrow message="Error deleting from Cloudinary: #stResult.error.message#" detail="#stResponse.filecontent.toString()#">
			<cfelse>
				<!--- Cloudinary threw error, no information --->
				<cfthrow message="Error deleting from Cloudinary" detail="#stResponse.filecontent.toString()#">
			</cfif>
		</cfif>
		
		<cfreturn stResult>
	</cffunction>

	<cffunction name="getInfo" access="public" output="false" returntype="struct">
		<cfargument name="file" type="string" required="true">

		<cfset var stResponse = structnew()>
		<cfset var publicID = getID(arguments.file)>
		<cfset var stResult = structnew()>
		
		<cfif not refindnocase("//res.cloudinary.com/", arguments.file)>
			<cfthrow message="Source has not been migrated to Cloudinary">
		</cfif>
		
		<cfhttp url="https://api.cloudinary.com/v1_1/#cloudName#/resources/image/upload/#publicID#" username="#apiKey#" password="#apiSecret#">
		
		<cfif isjson(stResponse.filecontent)>
			<cfset stResult = deserializejson(stResponse.filecontent)>
		</cfif>
		
		<cfif stResponse.StatusCode neq "200 Ok">
			<cfif structkeyexists(stResult,"error")>
				<!--- Cloudinary threw error, returned information --->
				<cfthrow message="Error querying Cloudinary: #stResult.error.message#" detail="#stResponse.filecontent.toString()#">
			<cfelse>
				<!--- Cloudinary threw error, no information --->
				<cfthrow message="Error querying Cloudinary" detail="#stResponse.filecontent.toString()#">
			</cfif>
		</cfif>
		
		<cfreturn stResult>
	</cffunction>
	
</cfcomponent>