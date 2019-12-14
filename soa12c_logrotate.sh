##########################
# Sampath Kunapareddy    #
# sampath.a926@gmail.com #
##########################
#!/bin/bash
#set -x
SCRIPT='logSOArotate.log'
RUNDATE=`date '+%Y-%m-%d-%H.%M.%S'`
FILEDATE=`date '+%m%d%y'`
CURRENT_SERVER=`hostname`
CURRENT_ENV=`hostname | cut -c3-5`
OUTDIR="/var/logs/Middleware"

rotate_script_log() {
   #Rotate Script Output     # Check that we can log to the standard dir
   if [ -d ${OUTDIR} ]; then   #dir exists
        LOG_FILE="${OUTDIR}/${SCRIPT}"
   else
        mkdir -p ${OUTDIR}
        if [ -d ${OUTDIR} ]; then			 	# dir now exists - continue
            LOG_FILE="${OUTDIR}/${SCRIPT}"
        else									# dir unable to be created - log to /var/tmp
            LOG_FILE="/var/tmp/${SCRIPT}"
        fi
   fi
   #Rotate Log Files
   if [ -f $LOG_FILE ]; then
     filesize=$(stat -c%s $LOG_FILE)
     echo -e "\n\nsize of $LOG_FILE = $filesize bytes"  2>&1 | tee -a ${LOG_FILE}
     if  [ $filesize -ge 100000 ]; then
        echo "rotating log $LOG_FILE " 2>&1 | tee -a ${LOG_FILE}
        ls $LOG_FILE* | grep -v lost+found |grep -v .gz | xargs -rt gzip
        [ -f $LOG_FILE".2.gz" ] && mv $LOG_FILE".2.gz" $LOG_FILE".3.gz"
        [ -f $LOG_FILE".1.gz" ] && mv $LOG_FILE".1.gz" $LOG_FILE".2.gz"
        mv $LOG_FILE".gz" $LOG_FILE".1.gz"
     fi
   else
     touch $LOG_FILE
   fi
   chmod 644 $LOG_FILE
}

rotate_out_log() {
    ##--  find all of the .out logs greater than 20M --##
    outfiles=`find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*.out' -size +20M`
    for outfile in $outfiles; do
      outdir=`echo ${outfile%/*}`
      outname=`echo ${outfile##*/}`
      echo '----------' >> $LOG_FILE 2>&1
      echo $RUNDATE, $outdir, $outname >> $LOG_FILE 2>&1

      ##--  find the next log number --##
      dirnum=`ls -rt $outdir"/"$outname"0"* | tail -n-1`     #getting old log name
      logstring=`echo ${dirnum##*.}`                         #getting old log number
      lognum=$(printf "%05d" `expr ${logstring:3:5} + 1`)    #Incrementing old log num by one 
      cp $outdir"/"$outname $outdir"/"$outname$lognum        #Copying existing with new number from above
      cat /dev/null > $outdir"/"$outname                     #nullifying the existing .out

      ##--  keep 40 .out logs;  zip all but latest 2 .out logs --##
      ls -t $outdir/$outname* | tail -n+200 | xargs -rt /bin/rm  >> $LOG_FILE 2>&1
      ls -t $outdir/*.out* | tail -n+3 | grep -v .gz  | xargs -rt gzip  >> $LOG_FILE 2>&1
    done
	logfiles=`find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*.log' -size +20M`
    for logfile in $logfiles; do
      logdir=`echo ${logfile%/*}`
      logname=`echo ${logfile##*/}`
      echo '----------' >> $LOG_FILE 2>&1
      echo $RUNDATE, $logdir, $logname >> $LOG_FILE 2>&1

      ##--  find the next log number --##
      dirnum=`ls -rt $logdir"/"$logname"0"* | tail -n-1`     #getting old log name
      logstring=`echo ${dirnum##*.}`                         #getting old log number
      lognum=$(printf "%05d" `expr ${logstring:3:5} + 1`)    #Incrementing old log num by one 
      cp $logdir"/"$logname $logdir"/"$logname$lognum        #Copying existing with new number from above
      cat /dev/null > $logdir"/"$logname                     #nullifying the existing .out

      ##--  keep 40 .out logs;  zip all but latest 2 .out logs --##
      ls -t $logdir/$logname* | tail -n+200 | xargs -rt /bin/rm  >> $LOG_FILE 2>&1
      ls -t $logdir/*.out* | tail -n+3 | grep -v .gz  | xargs -rt gzip  >> $LOG_FILE 2>&1
    done	
	_DOMS=$(ls -d /opt/oracle/admin/*_domain | awk -F "/" '{print $NF}' | sort -u)
	for _DOM in $_DOMS; do
	  if [[ $_DOM == "soa122_domain" ]]; then
        find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*.out*' | xargs chmod 600
        find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*.log*' | xargs chmod 600
	  else
        find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*.out*' | xargs chmod 644
        find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*.log*' | xargs chmod 644
	  fi
	done  
}

zip_diagnostic_log() {
  if [[ $CURRENT_ENV == "prd" ]]; then
    KEEP_LIMIT=4000
  elif [[ $CURRENT_ENV == "prf" ]]; then
    KEEP_LIMIT=1000
  else
    KEEP_LIMIT=200
  fi

##--  find all of the diagnostic logs greater than 20M --##
  logfiles=`find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*diagnostic.log' -size +20M`
  for logfile in ${logfiles}; do
    logdir=`echo ${logfile%/*}`
    logname=`echo ${logfile##*/}`
    basename=`echo ${logname%.*}`
    echo '##########' >> $LOG_FILE 2>&1
    echo $RUNDATE, $logdir, $logname >> $LOG_FILE 2>&1

    ##--  keep last $KEEP_LIMIT *diagnostic* logs;  zip all but latest 8 *diagnostic* logs --##
    ls -t $logdir/*diagnostic-* | tail -n+$KEEP_LIMIT | xargs -rt /bin/rm  >> $LOG_FILE 2>&1
    ls -t $logdir/*diagnostic-* | tail -n+9 | grep -v .gz  | xargs -rt gzip  >> $LOG_FILE 2>&1
    chmod 644 $logdir/*.gz
  done
  find /opt/oracle/admin/*_domain/*server/*_domain/servers/*/logs -name '*.gz' | xargs chmod 644
}

cleanup_middleware_logs() {
   if [[ $CURRENT_ENV == "prd" || $CURRENT_ENV == "prf" ]]; then
       KEEP_LIMIT=400
   else
       KEEP_LIMIT=200
   fi
   ##--  keep last $KEEP_LIMIT *wlst* logs;  --##
   ls -t /opt/oracle/middleware/logs/wlst_* 2>/dev/null | tail -n+$KEEP_LIMIT | xargs -rt /bin/rm  >> $LOG_FILE 2>&1
}

domain_cleanup() {
   DOMAIN_NAME=`echo $1`
   MAPP_SERVER=`echo $2`
   _DAYS=`echo $3`
   DOMAIN_TYPE=`echo $DOMAIN_NAME | awk '{print substr($0,0,3)}'`  
   if [ ${MAPP_SERVER} = "AdminServer" ]
   then
      AS="aserver"
      _DIR=/opt/oracle/admin/$DOMAIN_NAME/aserver/$DOMAIN_NAME/servers/AdminServer/tmp
      echo "Removing files older than $_DAYS days from $_DIR" >> $OUTDIR/$SCRIPT 2>&1
      find $_DIR -maxdepth 1 -name '.app*' -mtime +$_DAYS  -type d -print -exec rm -rf  {} \; >> $OUTDIR/$SCRIPT 2>&1
   else
      AS="mserver"
      # Below added per Bala
      if [ ${DOMAIN_TYPE} = "b2b" ]
      then
           find /var/applications/callout/logs -maxdepth 1 -name '*.log' -mtime +60 -type f -print -exec rm -rf  {} \; >> $OUTDIR/$SCRIPT 2>&1
      fi
   fi
}

rotate_script_log
rotate_out_log
zip_diagnostic_log
cleanup_middleware_logs

###  domain cleanup #######
case `hostname` in
   ux10|ux11|uxunt10|uxunt11|uxfit10|uxfit11)
      domain_cleanup soa121_domain AdminServer 5
      domain_cleanup soa121_domain soa121a 3
      domain_cleanup soa121_domain soa121b 5
      ;;
   ux1312|ux|uxtrn12|uxtrn|uxunt12|uxunt|uxfit12|uxfit)
      domain_cleanup soa122_domain AdminServer 5
      domain_cleanup soa122_domain soa121a 3
      domain_cleanup soa122_domain soa121b 5
      ;;
   *)
      echo "no domain cleanup"
      ;;
esac
