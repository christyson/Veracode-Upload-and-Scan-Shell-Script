# veracodeuploadandscan.sh
A shell script to upload and scan a application (zip or war etc.) and create the application if necessary.  Uses Curl and hmac headers

veracodeuploadandscan.sh is a sample script to upload and scan an application with Veracode using curl and hmac headers
        
Where the Command line options are:

    -h,--help       prints the help information
    -d,--debug			prints debugging information
    --app 				  "<your appname>"
     						      The name of the Veracode Platform application profile you want to scan in
    --file				  "<filename to upload>"
           				    The filename of the file you want to scan (for this script its best to upload a single file as a zip or war etc).
           				    Note: if there are spaces it will need to be surrounded by "s
    --filepath			"<full path to filename to upload>"
    	    				    The complete filepath to the file to be uploaded 
    						      Note: escape the final \ with an extra \ (i.e. c:\mystuff\example\\) and if there are spaces it 
                            will need to be surrounded by "s
    --crit				  "<businsess criticality of the app>"
           				    Valid values are Case-sensitive enum values and are: Very High, High, Medium, Low, and Very Low
							        Note: the value should be surrounded by "s
    --vid				    <your Veracode ID>
    --vkey         	<your Veracode Key>
           				    Your API credentials VERACODE_ID and VERACODE_KEY which you can generate (and revoke) from the UI
    --usecreds, -uc	use the Veracode ID and Key credentials stored in ~/.veracode/credentials

 Example innvocation using stored credentials separated on to two lines for readability but it should be one line

	./veracodeuploadandscan.sh --app=verademoscript --file="my.war" --filepath="C:\\Users\\myuser\\DemoStuff\\shell script\\" 
	--crit="Very High" --usecreds

 Example innvocation using provided credentials separated on to two lines for readability but it should be one line

	./veracodeuploadandscan.sh --app=verademoscript --file="my.war" --filepath="C:\\Users\\myuser\\DemoStuff\\shell script\\" 
	--crit="Very High" --vid=a251a1d**************** --vkey=312054************
