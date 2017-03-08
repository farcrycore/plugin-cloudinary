<!--- @@displayname: Cloudinary Migrator - Update Images in RichText Field --->
<!--- @@fuAlias: migrator-richtext-upate --->
<!--- /cloudinary/migrator-richtext-upate --->
<!--- @@cachestatus: -1 --->
<!--- @@proxycachetimeout: -1 --->

<!--- 
use Farcry setData() to update type's richtext field'
only accept method = POST
check  hash(objectid+typename+oldval+newval+cloudinarysecret)
 --->

<!--- todo: remove dev --->
<cfparam name="FORM.objectid" default="">
<cfparam name="FORM.typename" default="">
<cfparam name="FORM.field"    default="">
<cfparam name="FORM.urlOld"   default="">
<cfparam name="FORM.urlNew"   default="">
<cfparam name="FORM.hash"     default="">

<cfscript>
	boolean function findRecord
		(
			required string objectid,
			required string typename
		) 
	{
		var qryFind = new Query()
		    qryFind.setDatasource(APPLICATION.dsn);
			qryFind.setSQL("SELECT count(*) as cnt FROM refObjects where typename = :typename and objectid = :objectid");
			qryFind.addParam(name="typename", cfsqltype="cf_sql_varchar", value=ARGUMENTS.typename);
			qryFind.addParam(name="objectid", cfsqltype="cf_sql_varchar", value=ARGUMENTS.objectid);
			
			
		var qryFindResults = qryFind.execute().getResult();		
		return (qryFindResults.cnt == 1);
	}
	
	try {
		REQUEST.mode.BADMIN = FALSE;
		stReturn = {};
		statusCode = 500;
		
		
		if ( cgi.request_method == 'GET') { // POST
			system            = createObject("java", "java.lang.System");
			cloudinarysecret  = system.getEnv("CLOUDINARY_API_SECRET");
			
			//test hash
			if ( FORM.objectid != '' && FORM.typename != '' && FORM.field != '' && FORM.urlOld != '' && FORM.urlNew != '' && FORM.hash == hash(FORM.objectid&FORM.typename&FORM.field&FORM.urlOld&FORM.urlNew&cloudinarysecret)) {
// ALL GOOD - so far
				if ( findRecord(FORM.objectid,FORM.typename) ) {
					var stObj = application.fapi.getContentObject(FORM.objectid,FORM.typename);

					var before = stObj[FORM.field];
					stObj[FORM.field] = replace(stObj[FORM.field], FORM.urlOld, FORM.urlNew);
					var after = stObj[FORM.field];
					
					if (before != after) {
						stObj['DATETIMELASTUPDATED'] = Now();
						stObj['LASTUPDATEDBY'] = 'Cloudinary Migrator';
						var auditNote = "Cloudinary Migrator: update image from '#FORM.urlOld#' to '# FORM.urlNew#'";
						var stUpdate = application.fapi.setData(objectid=FORM.objectid, typename=FORM.typename ,stProperties=stObj, auditNote=auditNote, bAudit=1);
						
						if (stUpdate.bSuccess) {
							statusCode          = 200;
							stReturn['message'] ="OK";
							stReturn['detail']  = auditNote;
						} else {
							statusCode         = 500;
							stReturn['error']  = stUpdate;
							stReturn['detail'] = "TODO: better error handling required here";
						}
					}
					else {
						statusCode          = 412;
						stReturn['message'] = "Precondition Failed";
						stReturn['detail']  = "No image links to update";
					}
				}
				else {
					statusCode          = 404;
					stReturn['message'] = "Not Found";
					stReturn['detail']  = "No record in #FORM.typename# for objectID FORM.objectid";
				}
			}
			else {
				statusCode          = 400;
				stReturn['message'] = "Bad Request";
				stReturn['detail']  = "Hash() failed";
//stReturn.hash = hash(FORM.objectid&FORM.typename&FORM.field&FORM.urlOld&FORM.urlNew&cloudinarysecret);
			}
		} 
		else {
			statusCode          = 405;
			stReturn['message'] ="Method Not Allowed";
			stReturn['detail']  = "";
		}
		
	
	}
	catch (any error) {
		statusCode     = 500;
		stReturn['message'] = error.message;
		stReturn['detail']  = error.detail;
	}

	content reset="true" type="application/json";
	header statuscode="#statusCode#";
	WriteOutput(serializeJSON(stReturn));
</cfscript>
<!--- 

<h2> <img src="//res.cloudinary.com/migrator/image/fetch/q_auto,c_fill,w_80,h_80,g_faces:center,f_auto/http%3A%2F%2Fdae%2Denv%2Dcloudinarymigrator%2Es3%2Eamazonaws%2Ecom%2Fdev%2Fimages%2FdmImage%2FSourceImage%2Fajm%2Dtest%2D2017%2D03%2D08%2D0D33D635%2D1211%2D4859%2D95B8936C62979BD3%5F%5F%5F1%2Epng" border="0" alt="" /></h2> <h2>Play with the Demo</h2> <p>The FarCry Express demo is fully functional. It’s only a sample application, but it should give you a feel for how FarCry works and is a great starting point for building your own tailor made CMS solutions.</p> <p><strong>Contributor Guide</strong> There’s a comprehensive guide to editing and contributing in the FarCry environment.</p> <p><strong>Typography Page</strong> The typography page shows examples of all the various styles and classes for the Fandango theme in action. Just <code>view source</code> on your browser to see exactly how these styles are implemented.</p> <h2>Downloading &amp; Installing</h2> <p>When you’ve finished with the Demo you might want to consider getting a proper installation going in your development and production environments.</p> <p>The <a href="http://www.farcrycore.org/download">FarCry Core Downloads</a> page has all the latest builds available.</p> <p>Be sure to consult the [FarCry Installation Guide] when installing for the first time. The FarCry frameowrk is pretty flexible in terms of installation configuration, but its a good idea to get a handle on the basics first.</p> <h2>Building Stuff</h2> <p>Once you’ve got your own FarCry installation going, you will want to have a crack at building something. We have a bunch of handy resources for that:</p> <ul> <li><a href="https://farcry.jira.com/wiki/display/FCDEV60/Book+of+FarCry">Developer Course</a>: the Daemon FarCry Developer Course is freely available for anyone to follow along</li> <li><a href="https://farcry.jira.com/wiki/display/FCDEV60/Home">Documentation WIKI</a>: a truck load of documentation on all aspects of the FarCry publishing platform</li> </ul> <h2>Community Support</h2> <p>If you get stuck, give us a shout! The FarCry developer community is a friendly, if motley, crew of ColdFusion developers united by our love of FarCry.</p> <ul> <li><a href="http://groups.google.com/group/farcry-dev">Forums/Mailing list</a> is friendly! Ask questions, we want to help</li> <li><a href="http://www.farcrycore.org/blog">Committers Blog</a> contains regular tips, announcements of upcoming features and more</li> <li><a href="http://www.farcrycore.org/search">FarCry Google Custom Index</a> covers all the official FarCry websites for development, forums, plugins, documentation and regular FarCry bloggers</li> </ul> <h2>Commercial Support</h2> <p>If you want some professional help, look no further than <a href="http://www.daemon.com.au">the Daemonites</a>. We built FarCry and have a business based on servicing the FarCry developer community.</p> <ul> <li>Instructor Led Training</li> <li>Development: Fixed Cost Projects &amp; Time and Materials</li> <li>Mentoring &amp; Code Review</li> <li>Commercial License (for when the GPL is too restrictive for your company)</li> </ul>

--->