#!/bin/sh
#set -x
FILE="/opt/oracle/scripts/*properties*"
PROPFILE=`find $FILE | xargs grep "admin_user\|admin_password" | cut -d":" -f1 | sort -u`
if [ -f $PROPFILE ]; then
  # SCRIPT_PATH=$(dirname $0)
  SCRIPT=$(readlink -f $0)
  SCRIPT_PATH=$(dirname $SCRIPT)
  PYSCRIPT="${SCRIPT_PATH}/mscontrol.py"
  
  WL_HOME="$1"
  export WL_HOME
  
  BEA_JAVA_HOME="$2"
  JAVA_HOME="${BEA_JAVA_HOME}"
  export JAVA_HOME
  
  start() {
  ${WL_HOME}/../oracle_common/common/bin/wlst.sh -loadProperties ${PROPFILE} ${PYSCRIPT}
  }
  
  stop() {
  ${WL_HOME}/../oracle_common/common/bin/wlst.sh -loadProperties ${PROPFILE} ${PYSCRIPT}
  }
  
  status() {
  echo "" >| ${PYSCRIPT}
  echo "connect(admin_user, admin_password, host_url)" >> ${PYSCRIPT}
  echo "servers=cmo.getServers()" >> ${PYSCRIPT}
  echo "print \"-------------------------------------------------------\"" >> ${PYSCRIPT}
  echo "print \"\t\"+cmo.getName()+\" domain status\"" >> ${PYSCRIPT}
  echo "print \"-------------------------------------------------------\"" >> ${PYSCRIPT}
  echo "for server in servers:" >> ${PYSCRIPT}
  echo "        state(server.getName(),server.getType())" >> ${PYSCRIPT}
  echo "print \"-------------------------------------------------------\"" >> ${PYSCRIPT}
  
  ${WL_HOME}/../oracle_common/common/bin/wlst.sh -loadProperties ${PROPFILE} ${PYSCRIPT}
  }
  
  restart() {
    stop
    sleep 10
    start
    sleep 2
    status
  }
  
  pyscript() {
  echo "" >| ${PYSCRIPT}
  echo "import socket;" >> ${PYSCRIPT}
  #echo "admin_server_listen_address = socket.gethostname();" >> ${PYSCRIPT}
  #echo "admin_server_url = 't3://' + admin_server_listen_address + ':' + admin_server_listen_port;" >> ${PYSCRIPT}
  echo " " >> ${PYSCRIPT}
  echo "print 'CONNECT TO ADMIN SERVER';" >> ${PYSCRIPT}
  echo "connect(admin_user, admin_password, host_url);" >> ${PYSCRIPT}
  echo " " >> ${PYSCRIPT}
  echo "all_servers = cmo.getServers();" >> ${PYSCRIPT}
  echo "servers = [];" >> ${PYSCRIPT}
  echo "for server in all_servers:" >> ${PYSCRIPT}
  echo "    if (server.getName() != 'AdminServer' and server.getCluster() is not None):" >> ${PYSCRIPT}
  echo "        servers.append(server);" >> ${PYSCRIPT}
  echo " " >> ${PYSCRIPT}
  echo "machines = cmo.getMachines();" >> ${PYSCRIPT}
  echo "for machine in machines:" >> ${PYSCRIPT}
  echo "    node_manager_listen_address = machine.getNodeManager().getListenAddress();" >> ${PYSCRIPT}
  echo "    node_manager_listen_port = machine.getNodeManager().getListenPort();" >> ${PYSCRIPT}
  echo "    print 'CONNECT TO NODE MANAGER ON ' + node_manager_listen_address + ':' + repr(node_manager_listen_port);" >> ${PYSCRIPT}
  echo "    nmConnect(nm_user, nm_password, node_manager_listen_address, node_manager_listen_port, domain_name, domain_dir, 'ssl');" >> ${PYSCRIPT}
  echo "    for server in servers:" >> ${PYSCRIPT}
  echo "        if (node_manager_listen_address == server.getListenAddress()):" >> ${PYSCRIPT}
  if [[ $1 == "start" ]]; then
    echo "            print 'STARTING SERVER ' + server.getName();" >> ${PYSCRIPT}
    echo "            start(server.getName(),'Server');" >> ${PYSCRIPT}
  elif [[ $1 == "stop" ]]; then
    echo "            print 'SHUTDOWN SERVER ' + server.getName();" >> ${PYSCRIPT}
    echo "            shutdown(server.getName(),'Server','true',1000,'true');" >> ${PYSCRIPT}
  fi
  echo "    print 'DISCONNECT FROM NODE MANAGER ON ' + node_manager_listen_address + ':' + repr(node_manager_listen_port);" >> ${PYSCRIPT}
  echo "    nmDisconnect();" >> ${PYSCRIPT}
  echo " " >> ${PYSCRIPT}
  echo "print 'DISCONNECT FROM THE ADMIN SERVER';" >> ${PYSCRIPT}
  echo "disconnect();" >> ${PYSCRIPT}
  }
  case $3 in
    START)
      pyscript start
      start
      sleep 2
      status
      ;;
    STOP)
      pyscript stop
      stop
      ;;
    RESTART)
      restart
      ;;
    STATUS)
      status
      ;;
    *)
    echo -e "\e[1;31mUsage: $0 WL_HOME JAVA_HOME {START|STOP|STATUS|RESTART}\e[0m"
    exit 1
  esac
  rm mscontrol.py 2>/dev/null
else
  echo ""
  echo -e "\e[1mPlease check for ${PROPFILE} or any similar file..OR..change file name in $0 script"
  echo -e "\n## Make sure it has below entries: ##\e[0m"
  echo -e "\nadmin_user=wls_*_admin"
  echo -e "admin_password="
  echo -e "host_url=t3://[hostname]:7001"
  echo -e "nm_user=wls_*_admin"
  echo -e "nm_password="
  echo -e "nm_port=5556"
  echo -e "domain_name=*_domain"
  echo -e "domain_dir=/opt/oracle/admin/*_domain/aserver/*_domain"
  echo -e "\n\n"
fi
