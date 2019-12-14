##########################
# Sampath Kunapareddy    #
# sampath.a926@gmail.com #
##########################
#!/bin/bash
#set -x
#JmsCheck.sh |mailx -s "View PROD JMS_CHECK"  "src@gmail.com"
MAILX='mailx'
which $MAILX > /dev/null 2>&1
SUBJECT="JobNotificationQueue Count $DATE"

echo 'connect('soa_domain_admin','xxxxxx','t3://hostname.com:7001')' >> ${PYTHONSCRIPT}
echo 'servers=domainRuntimeService.getServerRuntimes();' >> ${PYTHONSCRIPT}
echo 'sum = 0' >> ${PYTHONSCRIPT}
echo 'if (len(servers) > 0):' >> ${PYTHONSCRIPT}
echo '    for server in servers:' >> ${PYTHONSCRIPT}
echo '        jmsRuntime=server.getJMSRuntime();' >> ${PYTHONSCRIPT}
echo '        jmsServers=jmsRuntime.getJMSServers();' >> ${PYTHONSCRIPT}
echo '        for jmsServer in jmsServers:' >> ${PYTHONSCRIPT}
echo '            destinations=jmsServer.getDestinations();' >> ${PYTHONSCRIPT}
echo '            for destination in destinations:' >> ${PYTHONSCRIPT}
echo '                J1=destination.getName()' >> ${PYTHONSCRIPT}
echo '                J2=destination.getMessagesCurrentCount()' >> ${PYTHONSCRIPT}
echo '                J3=destination.getMessagesPendingCount()' >> ${PYTHONSCRIPT}
echo '                sum += J3' >> ${PYTHONSCRIPT}
echo '                print 'JMS_MSG_COUNT:',J1,J2,J3' >> ${PYTHONSCRIPT}
echo 'print 'JMS_MSG_COUNT:JobNotificationQueue :', sum' >> ${PYTHONSCRIPT}

/opt/oracle/oracle_common/common/bin/wlst.sh /opt/Test/ksampath/checks/jmscheck.py
