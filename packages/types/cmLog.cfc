<cfcomponent displayname="Cloudinary Migrator Log" extends="farcry.core.packages.types.types" output="false" bObjectBroker="false">

	<cfproperty 
		name="farcryTypename" ftLabel="Farcry Type"
		type="string" required="true"
		ftSeq="1" ftWizardStep="Migrator" ftFieldset="Properties" 
		ftValidation="required">
		
	<cfproperty 
		name="FarcryFieldName" ftLabel="Farcry Field Name"
		type="string" required="true"
		ftSeq="2" ftWizardStep="Migrator" ftFieldset="Properties" 
		ftValidation="required">
	
	<cfproperty 
		name="farcryObjectID" ftLabel="Farcry Object ID"
		type="string" required="true"
		ftSeq="3" ftWizardStep="Migrator" ftFieldset="Properties" 
		ftValidation="required">

	<cfproperty 
		name="urlCloudinary" ftLabel="Cloudinary URL"
		type="string" required="true" ftType="longchar" dbprecision="1000"
		ftSeq="4" ftWizardStep="Migrator" ftFieldset="Properties" 
		ftValidation="required">
	
	<cfproperty 
		name="urlS3" ftLabel="S3 URL"
		type="string" required="true" ftType="longchar" dbprecision="1000"
		ftSeq="5" ftWizardStep="Migrator" ftFieldset="Properties" 
		ftValidation="required">

<!--- 	<cfproperty 
		name="workFlowStatus" ftLabel="Status"
		type="string" required="true"
		ftSeq="6" ftWizardStep="Migrator" ftFieldset="Work Flow" 
		ftHint="[added|downloaded|uploaded|updateRichText|deletedFromCloudinary|completed]"
		ftValidation="required"> --->

<!--- 	<cfproperty 
		name="aMessages" ftLabel="Message"
		ftHint="procces messages and errors"
		type="array" required="false"
		ftSeq="7" ftWizardStep="Migrator" ftFieldset="Log" 
		ftType="array" ftJoin="cmMessage"
		ftAllowAttach="true" ftAllowAdd="true" ftAllowEdit="true" ftRemoveType="detach"> --->





</cfcomponent>