##########################
# Sampath Kunapareddy    #
# sampath.a926@gmail.com #
##########################
#!/bin/bash
#set -x
declare -a pids

waitPids() {
  while [ ${#pids[@]} -ne 0 ]; do
    #echo "Waiting for pids: ${pids[@]}"
    local range=$(eval echo {0..$((${#pids[@]}-1))})
    local i
    for i in $range; do
      if ! kill -0 ${pids[$i]} 2> /dev/null; then
        #echo "Done -- ${pids[$i]} ***********************"
        unset pids[$i]
      fi
    done
    pids=("${pids[@]}") # Expunge nulls created by unset.
    sleep 1
  done
  #echo "Done!"
}

addPid() {
  desc=$1
  pid=$2
  echo "$desc -- $pid ***********************"
  pids=(${pids[@]} $pid)
}

start_otm() {
otm_url="http://<%= $facts['fqdn'] -%>:<%= $otm_port -%>/GC3/glog.webserver.test.TestTierServlet"
maxServlet=20
for (( i=1; i < $maxServlet; i++ )); do
  if [[ $? == 99 ]]; then exit 1; fi
  echo "Checking for 200 http status code - $i of $maxServlet"
  #RC=$(curl -s -o /dev/null -I -w "%{http_code}" $otm_url)
  RC=$(curl -s -o  /dev/null -I -w "%{http_code}" "http://tmut3.intra.schneider.com/GC3/glog.webserver.servlet.umt.Login")
  #echo "Return code $RC" | tee -a ${LOG_OUT}
  if [[ $RC == '200' ]]; then
     break;
  fi
  sleep 30
done
if [ $i -ge $maxServlet ]; then
  echo -e "!!Did not receive valid status code from test servlet - OTM likely did not start correctly"
  return 1
fi
}

check_system_activiation() {
OTM_LOGFILE="/opt/oracle/otm/logs/glog.app.log"
TSTAMP=$(cat ${OTM_LOGFILE} | grep "^20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" | tail -1 | awk '{print $1" "$2}')

#In the above command
#added head for example
#actual will have tail

flag=1; count=0
while [[ $flag -ne 2 ]]; do
  echo -e "Itteration ${count}/5..."
  sleep 1
  TLINES=$(cat ${OTM_LOGFILE} | wc -l)
  if [[ ! -z $(cat ${OTM_LOGFILE} | grep -A${TLINES} "${TSTAMP}" | grep "End of system activation") ]]; then
    echo "Entrie found"
    flag=2; exit 33
  fi
   ((count++))
   if [[ $count -eq 5 ]]; then
        echo -e "Tried 5 times no match found, so killing URL test"
        kill -9 $1
        exit 99
   fi
done
}

start_otm &
addPid "url check" $!
export start_otm_pid=$!
check_system_activiation $start_otm_pid &
addPid "log file check" $!
export check_system_activiation_pid=$!

echo $start_otm_pid $check_system_activiation_pid

waitPids
