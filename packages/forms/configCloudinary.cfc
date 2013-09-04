<cfcomponent displayname="Cloudinary" hint="Cloudinary image hosting" extends="farcry.core.packages.forms.forms" output="false" persistent="false" key="cloudinary">

	<cfproperty ftSeq="1" ftFieldset="Cloudinary" ftLabel="Cloud name"
				name="cloudName" type="string" />
				
	<cfproperty ftSeq="2" ftFieldset="Cloudinary" ftLabel="API Key"
				name="apiKey" type="string" />
				
	<cfproperty ftSeq="3" ftFieldset="Cloudinary" ftLabel="API Secret"
				name="apiSecret" type="string" />
	
	
</cfcomponent>