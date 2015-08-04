component {
	
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
		
		var format = "fl_keep_iptc";
		var pixels = "";
		
		switch (lcase(arguments.crop)){
			case "forcesize":
				// Simply force the resize of the image into the width/height provided
				format = listappend(format,"c_scale");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}

				break;
			
			case "fitinside":
				format = listappend(format,"c_fit");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}

				break;
			
			case "croptofit":
				format = listappend(format,"c_fill");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}
				
				break;
	
			case "pad":
				format = listappend(format,"c_pad");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
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
				format = listappend(format,"c_fill");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}
				
				switch (arguments.crop){
					case "center":
						format = listappend(format,"g_faces");
						break;
					case "topleft":
						format = listappend(format,"g_north_west");
						break;
					case "topcenter":
						format = listappend(format,"g_north");
						break;
					case "topright":
						format = listappend(format,"g_north_east");
						break;
					case "left":
						format = listappend(format,"g_west");
						break;
					case "right":
						format = listappend(format,"g_east");
						break;
					case "bottomleft":
						format = listappend(format,"g_south_west");
						break;
					case "bottomcenter":
						format = listappend(format,"g_south");
						break;
					case "bottomright":
						format = listappend(format,"g_south_east");
						break;
				}

				break;
			
			default:
				if (refind("^\d+,\d+-\d+,\d+$",arguments.crop)){
					pixels = listtoarray(arguments.crop,",-");
					
					// crop to selected section
					format = listappend(format,"x_#pixels[1]#,y_#pixels[2]#,w_#pixels[3]-pixels[1]#,h_#pixels[4]-pixels[2]#,c_crop");
					
					// resize selected section to required size
					format = format & "/c_fit";
					
					if (arguments.Width gt 0){
						format = listappend(format,"w_#arguments.width#");
					}
					
					if (arguments.Height gt 0){
						format = listappend(format,"h_#arguments.height#");
					}
				}
		}
		
		switch (arguments.format){
			case "png":
				format = listappend(format,"f_png");
				break;
			case "auto":
				format = listappend(format, "f_auto");
		}

		return format;
	}

	public struct function getURLInformation(required string file) {
		var apiDomain = getAPIDomain();
		var cloudName = getCloudName();
		var uploadVia = application.fapi.getConfig("cloudinary", "uploadVia", "post");
		var autoUploadFolder = application.fapi.getConfig("cloudinary", "autoUploadFolder", "/nothing___here");
		
		var apiURLPrefix = "//" & apiDomain & "/" & cloudName & "/image";
		
		var reAPI = "^//" & replace(apiDomain, '.', '\.', 'ALL') & "/" & replace(cloudName, '.', '\.', 'ALL') & "/image";
		var reCDN = rereplace(rereplace(application.fc.lib.cdn.ioGetFileLocation(location="images", file="", bRetrieve=true, protocol="http").path, "([\.\?\+])", "\\1", "all"), "http:", "^(https?:)?");
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

		else if (refindnocase(reAuto, arguments.file)){
			stResult["type"] = "auto";
			stResult["source"] = rereplacenocase(arguments.file, reAuto, "\2");
			stResult["transformation"] = rereplace(arguments.file, reAuto, "\1")
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
			}
			stResult["transformation"] = rereplace(arguments.file, rePost, "\1");
			if (len(stResult["transformation"])){
				stResult["untransformed"] = apiURLPrefix & "/upload" & rereplace(arguments.file, rePost, "\2") & rereplace(arguments.file, rePost, "\3");
			};
			stResult["template"] = rereplace(stResult.untransformed, "/upload/", "/upload/{transformation}/");
		}

		else if (refind(reCDN, arguments.file)) {
			stResult["source"] = rereplace(arguments.file, reCDN, "/");

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

	public struct function upload(required string file, string publicID, string transformation){
		var sigTimestamp = DateDiff('s', CreateDate(1970,1,1), now());
		var sigSignature = "";
		var stResult = structnew();
		var cfhttp = structnew();
		var cloudName = application.fapi.getConfig("cloudinary", "cloudName", "");
		var apiKey = application.fapi.getConfig("cloudinary", "apiKey", "");
		var apiSecret = application.fapi.getConfig("cloudinary", "apiSecret", "");
		
		if (not len(cloudName) or not len(apiKey) or not len(apiSecret)){
			throw message="Cloudinary has not been configured - add the Cloud Name, API Key and API Secret";
		}
		
		sigSignature = lcase( hash( "public_id=#arguments.publicID#&timestamp=#sigTimestamp##apiSecret#" ,"SHA" ) );
		
		// UPLOAD TO CLOUDINARY
		http url="https://api.cloudinary.com/v1_1/#cloudName#/image/upload" method="POST" multipart="true" {
			httpparam type="formfield" name="api_key" value="#apiKey#";
			httpparam type="formfield" name="public_id" value="#arguments.publicID#";
			httpparam type="formfield" name="timestamp" value="#sigTimestamp#";
			httpparam type="formfield" name="signature" value="#trim(sigSignature)#";
			if (len(arguments.transformation)){
				httpparam type="formfield" name="transformation" value="#arguments.transformation#";
			}
			httpparam type="file" name="file" file="#application.fc.lib.cdn.ioReadFile(location='images',file=arguments.file,datatype='image').source#";
		}
		
		if (isjson(cfhttp.filecontent)){
			stResult = deserializejson(cfhttp.filecontent);
			stResult["urlWithSource"] = mid(stResult.url,6,len(stResult.url)) & "?source=#urlencodedformat(arguments.file)#";
		}
		
		if (cfhttp.StatusCode neq "200 Ok"){
			if (structkeyexists(stResult,"error")){
				// Cloudinary threw error, returned information
				throw(message="Error uploading to Cloudinary: #stResult.error.message#", detail="#cfhttp.filecontent.toString()#");
			}
			else {
				// Cloudinary threw error, no information
				throw(message="Error uploading to Cloudinary", detail="#cfhttp.filecontent.toString()#");
			}
		}
		
		return stResult;
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

	public struct function delete(required string file){
		var sigTimestamp = DateDiff('s', CreateDate(1970,1,1), now());
		var sigSignature = "";
		var stResult = structnew();
		var cfhttp = structnew();
		var publicID = "";
		var stInfo = getURLInformation(arguments.file);

		var cloudName = application.fapi.getConfig("cloudinary", "cloudName", "");
		var apiKey = application.fapi.getConfig("cloudinary", "apiKey", "");
		var apiSecret = application.fapi.getConfig("cloudinary", "apiSecret", "");
		
		if (not len(cloudName) or not len(apiKey) or not len(apiSecret)){
			throw(message="Cloudinary has not been configured - add the Cloud Name, API Key and API Secret");
		}
		
		if (stInfo.type != "post"){
			return {};
		}

		publicID = getID(arguments.file);
		sigSignature = lcase( hash( "public_id=#publicID#&timestamp=#sigTimestamp##apiSecret#" ,"SHA" ) );
		
		// DELETE FROM CLOUDINARY
		http url="https://api.cloudinary.com/v1_1/#cloudName#/resources/image/upload?public_ids=#publicID#" method="DELETE" username="#apiKey#" password="#apiSecret#";
		
		if (isjson(cfhttp.filecontent)){
			stResult = deserializejson(cfhttp.filecontent);
		}
		
		if (cfhttp.StatusCode neq "200 Ok"){
			if (structkeyexists(stResult,"error")){
				// Cloudinary threw error, returned information
				throw(message="Error deleting from Cloudinary: #stResult.error.message#", detail="#cfhttp.filecontent.toString()#");
			}
			else {
				// Cloudinary threw error, no information
				throw(message="Error deleting from Cloudinary", detail="#cfhttp.filecontent.toString()#");
			}
		}
		
		return stResult;
	}
	
	public struct function getInfo(required string file){
		var cfhttp = structnew();
		var publicID = getID(arguments.file);
		var stResult = structnew();
		
		if (not refindnocase("//res.cloudinary.com/",arguments.file)){
			throw(message="Source has not been migrated to Cloudinary");
		}
		
		http url="https://api.cloudinary.com/v1_1/#cloudName#/resources/image/upload/#publicID#" username="#apiKey#" password="#apiSecret#";
		
		if (isjson(cfhttp.filecontent)){
			stResult = deserializejson(cfhttp.filecontent);
		}
		
		if (cfhttp.StatusCode neq "200 Ok"){
			if (structkeyexists(stResult,"error")){
				// Cloudinary threw error, returned information
				throw(message="Error querying Cloudinary: #stResult.error.message#", detail="#cfhttp.filecontent.toString()#");
			}
			else {
				// Cloudinary threw error, no information
				throw(message="Error querying Cloudinary", detail="#cfhttp.filecontent.toString()#");
			}
		}
		
		return stResult;
	}
	
	public string function getID(required string file){
		
		return urldecode(listfirst(listlast(listfirst(arguments.file,"?"),"/"),"."));
	}
	
	public string function getSource(required string file){
		var stInfo = getURLInformation(arguments.file);

		return stInfo.source;
	}
	
}