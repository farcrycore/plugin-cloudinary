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

	public string function getTransform(numeric width=0, numeric height=0, string crop="FitInside"){
		
		var format = "fl_keep_iptc";
		var pixels = "";
		
		switch (arguments.crop){
			case "ForceSize":
				// Simply force the resize of the image into the width/height provided
				format = listappend(format,"c_scale");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}

				break;
			
			case "FitInside":
				format = listappend(format,"c_fit");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}

				break;
			
			case "CropToFit":
				format = listappend(format,"c_fill");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}
				
				break;
	
			case "Pad":
				format = listappend(format,"c_pad");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}
				
				break;
			
			case "center,topleft,topcenter,topright,left,right,bottomleft,bottomcenter,bottomright":
				format = listappend(format,"c_fill");
				
				if (arguments.width gt 0){
					format = listappend(format,"w_#arguments.width#");
				}
				
				if (arguments.height gt 0){
					format = listappend(format,"h_#arguments.height#");
				}
				
				switch (arguments.crop){
					case "center":
						format = listappend(format,"g_faces:center");
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
		
		return format;
	}
	
	public string function fetch(required struct cropParams, required string sourceURL) {

		var endpoint = getAPIEndpoint();
		var method = "image/fetch";
		var oldtransform = "";
		var transform = getTransform(arguments.cropParams);

		var fetchURL = "";
		var imageURL = arguments.sourceURL;

		if (refindnocase("^//" & replace(getAPIDomain(),'.','\.','ALL') & "/[^/]+/image/fetch/", imageURL)){
			// splice a new transform into an existing Cloudinary URL

			oldTransform = rereplace(imageURL, "^//" & replace(getAPIDomain(),'.','\.','ALL') & "/[^/]+/image/fetch/(.*)/https?://.*$","\1");
			fetchURL = replace(imageURL, oldTransform, transform);
		}
		else{
			// create a new Cloudinary URL

			if (len(imageURL) gt 2 && left(imageURL, 2) == "//") {
				imageURL = "http:" & imageURL;
			}

			fetchURL = "#endpoint#/#method#/#transform#/#imageURL#";
		}

		return fetchURL;
	}

}