<cfcomponent displayname="Cloudinary" hint="Cloudinary image hosting" extends="farcry.core.packages.forms.forms" output="false" persistent="false" key="cloudinary" fualias="cloudinary">

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
	

	<cfproperty ftSeq="10" ftFieldset="Options" ftLabel="Automatic Image File Format"
				name="formatAuto" type="boolean" default="1" ftDefault="1"
				ftType="boolean" ftRenderType="checkbox"
				ftHint="Cloudinary will automatically select the best image format" />

	<cfproperty ftSeq="11" ftFieldset="Options" ftLabel="Automatic Image Quality"
				name="qualityAuto" type="boolean" default="1" ftDefault="1"
				ftType="boolean" ftRenderType="checkbox"
				ftHint="Cloudinary will automatically select the best image quality vs file size" />

	<cfproperty ftSeq="12" ftFieldset="Options" ftLabel="Apply Automatic Image Quality to Unsized Images"
				name="qualityAutoUnsized" type="boolean" default="1" ftDefault="1"
				ftType="boolean" ftRenderType="checkbox"
				ftHint="Cloudinary will automatically select the best image quality vs file size for images that are not to be resized" />

	<cfproperty ftSeq="13" ftFieldset="Options" ftLabel="Keep IPTC Metadata"
				name="keepIPTC" type="boolean" default="0" ftDefault="0"
				ftType="boolean" ftRenderType="checkbox"
				ftHint="Cloudinary will retain IPTC Metadata. NOTE: This will NOT WORK if automatic image quality is selected above." />


</cfcomponent>