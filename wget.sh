#!/bin/sh
#Generated 12/4/19 8:01 PM
#Start of user configurable variables
LANG=C
export LANG

#Trap to cleanup cookie file in case of unexpected exits.
trap 'rm -f $COOKIE_FILE; exit 1' 1 2 3 6

#SSO username
printf 'SSO UserName:'
read SSO_USERNAME

#Path to wget command
WGET=/usr/bin/wget

#Log directory and file
LOGDIR=.
LOGFILE=$LOGDIR/wgetlog-$(date +%m-%d-%y-%H:%M).log

#Print wget version info
echo "Wget version info:
------------------------------
$($WGET -V)
------------------------------" > "$LOGFILE" 2>&1

#Location of cookie file
COOKIE_FILE=$(mktemp -t wget_sh_XXXXXX) >> "$LOGFILE" 2>&1
if [ $? -ne 0 ] || [ -z "$COOKIE_FILE" ]; then
 echo "Temporary cookie file creation failed. See $LOGFILE for more details." |  tee -a "$LOGFILE"
 exit 1
fi
echo "Created temporary cookie file $COOKIE_FILE" >> "$LOGFILE"

#Output directory and file
OUTPUT_DIR=.

#End of user configurable variable

#The following command to authenticate uses HTTPS. This will work only if the wget in the environment
#where this script will be executed was compiled with OpenSSL. 
#
#BELOW command is just used to validate credentials and allow SSO to proceed with download step
 $WGET  --secure-protocol=auto --save-cookies="$COOKIE_FILE" --keep-session-cookies  --http-user "$SSO_USERNAME" --ask-password  "https://updates.oracle.com/Orion/Services/download" -O /dev/null 2>> "$LOGFILE"

#Verify if authentication is successful
if [ $? -ne 0 ]; then
 echo "Authentication failed with the given credentials." | tee -a "$LOGFILE"
 echo "Please check logfile: $LOGFILE for more details."
else
 echo "Authentication is successful. Proceeding with downloads..." >> "$LOGFILE"

 $WGET  --load-cookies="$COOKIE_FILE" "https://updates.oracle.com/Orion/Services/download/p30306404_188000_Generic.zip?aru=23116945&patch_file=p30306404_188000_Generic.zip" -O "$OUTPUT_DIR/p30306404_188000_Generic.zip"   >> "$LOGFILE" 2>&1 

fi

# Cleanup
rm -f "$COOKIE_FILE"
echo "Removed temporary cookie file $COOKIE_FILE" >> "$LOGFILE"
