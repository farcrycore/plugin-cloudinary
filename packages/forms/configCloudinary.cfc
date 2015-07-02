<cfcomponent displayname="Cloudinary" hint="Cloudinary image hosting" extends="farcry.core.packages.forms.forms" output="false" persistent="false" key="cloudinary">

	<cfproperty ftSeq="1" ftFieldset="Cloudinary" ftLabel="Cloud name"
				name="cloudName" type="string" />
				
	<cfproperty ftSeq="2" ftFieldset="Cloudinary" ftLabel="API Key"
				name="apiKey" type="string" />
				
	<cfproperty ftSeq="3" ftFieldset="Cloudinary" ftLabel="API Secret"
				name="apiSecret" type="string" />
	
	<cfproperty ftSeq="4" ftFieldset="Cloudinary" ftLabel="Upload Via"
				name="uploadVia" type="string" default="post" ftDefault="post"
				ftType="list" ftList="post:Post To API,fetch:Fetch From URL,auto:Auto Upload"
				ftHint="<a href='http://cloudinary.com/documentation/fetch_remote_images##remote_image_fetch_url' target='_blank'>Fetch From URL</a> requires that the images be publicly accessibe, and Cloudinary should be configured to only fetch from specific URLs<br><a href='http://cloudinary.com/documentation/fetch_remote_images##auto_upload_remote_images' target='_blank'>Auto Upload</a> must be preconfigured in Cloudinary, and the mapped folder entered below" />
	
	<cfproperty ftSeq="5" ftFieldset="Cloudinary" ftLabel="Auto Upload Folder"
				name="autoUploadFolder" type="string"
				ftHint="The auto upload folder for this appliation. Should start with '/'." />
	
	
</cfcomponent>