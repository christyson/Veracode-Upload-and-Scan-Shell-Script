# MIT License
#
# Copyright (c) 2019 Chris Tyson
# Author: Chris Tyson
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# When looking into this I was inspired by Matthias Gärtner's (https://gist.github.com/m9aertner) 
# "Using curl and openssl to access the Veracode API endpoint" ( https://gist.github.com/m9aertner/7ae804a5297617456f81c8b5a3a9305b) who showed how
# using plain shell scripting on the command line, it's possible to compute the Authorization header using openssl.
#
# For other interesting uses of the api see Veracode-Community-Projects page here: https://github.com/veracode/Veracode-Community-Projects
#

#
# Command line options:
#    -h,--help			prints the help information
#    -d,--debug			prints debugging information
#    --app 				"<your appname>"
#     						The name of the Veracode Platform application profile you want to scan in
#    --file				"<filename to upload>"
#           				The filename of the file you want to scan (for this script its best to upload a single file as a zip or war etc).
#           				Note: if there are spaces it will need to be surrounded by "s
#    --filepath			"<full path to filename to upload>"
#    	    				The complete filepath to the file to be uploaded 
#    						Note: escape the final \ with an extra \ (i.e. c:\mystuff\example\\) and if there are spaces it will need to be surrounded by "s
#    --crit				"<businsess criticality of the app>"
#           				Valid values are Case-sensitive enum values and are: Very High, High, Medium, Low, and Very Low
#							Note: the value should be surrounded by "s
#    --vid				<your Veracode ID>
#    --vkey         	<your Veracode Key>
#           				Your API credentials VERACODE_ID and VERACODE_KEY which you can generate (and revoke) from the UI
#    --usecreds, -uc	use the Veracode ID and Key credentials stored in ~/.veracode/credentials
#
# Example innvocation using stored credentials separated on to two lines for readability but it should be one line
#
#	./veracodeuploadandscan.sh --app=verademoscript --file="my.war" --filepath="C:\\Users\\myuser\\DemoStuff\\shell script\\" 
#	--crit="Very High" --usecreds
#
# Example innvocation using provided credentials separated on to two lines for readability but it should be one line
#
#	./veracodeuploadandscan.sh --app=verademoscript --file="my.war" --filepath="C:\\Users\\myuser\\DemoStuff\\shell script\\" 
#	--crit="Very High" --vid=a251a1d**************** --vkey=312054************

usage()
{

    printf "\n%s is a sample script to upload and scan an application with Veracode using curl and hmac headers\n\n" "$0"
    printf "\t-h,--help\t\tprints this message\n"
    printf "\t-d,--debug\t\tprints debugging information\n"
    printf "\t--app\t\t=\t\"<your appname>\"\n"
    printf "\t--file\t\t=\t\"<filename to upload>\"\n"
    printf "\t--filepath\t=\t\"<full path to filename to upload>\"\n"
    printf "\t\t\t\tNote: escape the final \\ with an extra \\ (i.e. c:\mystuff\\\example\\\\\\)\n"
    printf "\t--crit\t\t=\t\"<businsess criticality of the app>\"\n"
    printf "\t--vid\t\t=\t\"<your Veracode ID>\"\n"
    printf "\t--vkey\t\t=\t\"<your Veracode Key>\"\n"
    printf "\t--usecreds, -uc\t\tuse the Veracode ID and Key credentials stored in ~/.veracode/credentials\n"
}

generate_hmac_header ()
{
   # generate the hmac header for Veracode
   if [ "$DEBUG" == "on" ]; then
	  printf "\n\tGenerate the hmac header for URLPATH %s and METHOD %s\n" "$1" "$2"
   fi
   NONCE="$(cat /dev/random | xxd -p | head -c 32)"
   TS="$(($(date +%s%N)/1000))"
   URLPATH=$1
   METHOD=$2
   encryptedNonce=$(echo "$NONCE" | xxd -r -p | openssl dgst -sha256 -mac HMAC -macopt hexkey:$VERACODE_KEY | cut -d ' ' -f 2)
   encryptedTimestamp=$(echo -n "$TS" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedNonce | cut -d ' ' -f 2)
   signingKey=$(echo -n "vcode_request_version_1" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedTimestamp | cut -d ' ' -f 2)
   DATA="id=$VERACODE_ID&host=analysiscenter.veracode.com&url=$URLPATH&method=$METHOD"
   signature=$(echo -n "$DATA" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey | cut -d ' ' -f 2)
   VERACODE_AUTH_HEADER="VERACODE-HMAC-SHA-256 id=$VERACODE_ID,ts=$TS,nonce=$NONCE,sig=$signature"
}

if [ "$DEBUG" == "on" ]; then
   printf "\nDebug on\n"
fi

#set default business criticality
BUSINESSCRITICALITY="Very High"
USECREDS="off"

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
	    --debug | -d)
		    DEBUG="on"
			;;
	    --usecreds | -uc)
		    USECREDS="on"
			;;
        --app)
		    APP=$VALUE
            ;;
        --file)
		    FILE=$VALUE
            ;;
		--filepath)
		    FILEPATH=$VALUE
            ;;
        --crit)
		    BUSINESSCRITICALITY=$VALUE
            ;;
		--vid)
           VERACODE_ID=$VALUE
            ;;
		--vkey)
            VERACODE_KEY=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

if [ "$DEBUG" == "on" ]; then
   printf "\n\tDebug is on\n\n"
fi

if [[ $APP == "" ]] | [[ $FILE == "" ]] | [[ $FILEPATH == "" ]] | ( ([[ $VERACODE_ID == "" ]] | [[ $VERACODE_KEY == "" ]]) & [[ $USECREDS == "off" ]]); then
    printf "\n At a minimum you need to specify the app name, file name, file path, and your veracode ID and Key or --usecreds. Here is an example innvocation:\n"
    printf '\t./veracodeuploadandscan.sh --app=verademoscript --file="my.war" --filepath="C:\\Users\\myuser\\DemoStuff\\shell script\\ --crit="Very High" --vid=a251a1d**************** --vkey=312054************'
    usage
    exit 0
fi

if [ "$USECREDS" == "on" ]; then
   value=`ls ~/.veracode/credentials`
   while IFS= read -r line
   do
      if [[ "$line" =~ "default" ]]; then
	     IFS= read -r line
         VERACODE_ID="$(cut -d'=' -f2 <<<$line)"
         VERACODE_ID="${VERACODE_ID#"${VERACODE_ID%%[![:space:]]*}"}"
         if [ "$DEBUG" == "on" ]; then
            printf "\tVeracode ID from credentials is\t\t%s\n" "$VERACODE_ID"
         fi
	     IFS= read -r line
         VERACODE_KEY="$(cut -d'=' -f2 <<<$line)"
        VERACODE_KEY="${VERACODE_KEY#"${VERACODE_KEY%%[![:space:]]*}"}"
         if [ "$DEBUG" == "on" ]; then
            printf "\tVeracode Key from credentials is\t%s\n" "${VERACODE_KEY:0:5}**********"
         fi
	     break
      fi
   done < "$value"
fi

if [ "$DEBUG" == "on" ]; then
   printf "\n\tRunning %s with the following values\n\n" "$0"
   printf "\t--app\t\t=\t%s\n" "$APP"
   printf "\t--file\t\t=\t%s\n" "$FILE"
   printf "\t--filepath\t=\t%s\n" "$FILEPATH"
   printf "\t--crit\t\t=\t%s\n" "$BUSINESSCRITICALITY"
   printf "\t--vid\t\t=\t%s\n" "$VERACODE_ID"
   printf "\t--vkey\t\t=\t%s\n\n" "${VERACODE_KEY:0:5}**********"
fi

if [ "$DEBUG" == "on" ]; then
   printf "\tCheck if the %s profile exists, create it if it does not exist, and get the app id\n" "$APP"
fi
# get the applist from the platform
URLPATH=/api/5.0/getapplist.do
METHOD=GET
generate_hmac_header $URLPATH $METHOD
curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -o applist.xml

# check the applist to see if the application profile to be used exists
while read -r line
do
    app_name=$(echo $line | grep -Po 'app_name="\K.*?(?=")')
    app_id=$(echo $line | grep -Po 'app_id="\K.*?(?=")')
    if [ "$app_name" = "$APP" ]; then 
	   break
	fi
done < <(grep $APP applist.xml)

if [ "$app_name" = "$APP" ]; then 
   if [ "$DEBUG" == "on" ]; then
      printf "\n\tThe %s profile with app_id %s exists, not creating\n" "$APP" "$app_id"
   fi
else
   # create the app
   if [ "$DEBUG" == "on" ]; then
      printf "\t%s profile not found create it\n" "$APP"
   fi
   URLPATH=/api/5.0/createapp.do
   METHOD=POST
   generate_hmac_header $URLPATH $METHOD
   curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" https://analysiscenter.veracode.com/api/5.0/createapp.do -F "app_name=$APP" -F "business_criticality=$BUSINESSCRITICALITY" -o createapp.xml
   app_id=$(cat createapp.xml | grep -Po 'app_id="\K.*?(?=")')
fi 

# upload the file
UPLOAD=$FILEPATH$FILE
printf "\n\tUploading the file %s to %s\n" "$UPLOAD" "$APP"
URLPATH=/api/5.0/uploadfile.do
#URLPATH="/api/5.0/uploadlargefile.do"
METHOD=POST
generate_hmac_header $URLPATH $METHOD
curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" https://analysiscenter.veracode.com/api/5.0/uploadfile.do -F "app_id=$app_id" -F "file=@$UPLOAD" -o upload.xml
#curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" -i --data-binary "@$UPLOAD" -H "Content-Type: binary/octet-stream" "https://analysiscenter.veracode.com/api/5.0/uploadlargefile.do?app_id=$app_id&filename=$FILE" -o largeupload.xml

# start the scan

printf "\n\tStarting the prescan for %s with auto_scan true\n" "$APP"
URLPATH=/api/5.0/beginprescan.do
METHOD=POST
generate_hmac_header $URLPATH $METHOD
curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" https://analysiscenter.veracode.com/api/5.0/beginprescan.do -F "app_id=$app_id" -F "auto_scan=true" -o beginscan.xml
